class User < ApplicationRecord
  has_many :food_logs, dependent: :destroy

  before_validation :normalize_email_and_sex

  enum :activity_level,
       {
         sedentary: 1,
         lightly_active: 2,
         moderately_active: 3,
         very_active: 4,
         extra_active: 5
       },
       validate: true,
       suffix: true

  enum :goal_type, { lose: "lose", maintain: "maintain", gain: "gain" }, validate: true

  validates :email, presence: true, uniqueness: true
  validates :provider, presence: true
  validates :uid, presence: true
  validates :height_cm, numericality: { greater_than: 0 }, allow_nil: true
  validates :weight_kg, numericality: { greater_than: 0 }, allow_nil: true
  validates :daily_calories_goal,
            :daily_protein_goal_g,
            :daily_fats_goal_g,
            :daily_carbs_goal_g,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :sex, inclusion: { in: %w[male female] }, allow_nil: true

  scope :needing_survey, -> { where(survey_completed: false) }

  def self.find_or_create_from_auth_hash(auth)
    info = auth.fetch(:info, {})
    user = find_or_initialize_by(provider: auth[:provider], uid: auth[:uid])
    user.email = info[:email].presence || user.email
    user.save! if user.changed?
    user
  end

  def complete_survey!(attributes)
    assign_attributes(attributes)
    self.survey_completed = true

  manual_goals = attributes.slice(:daily_calories_goal, :daily_protein_goal_g, :daily_fats_goal_g, :daily_carbs_goal_g)
    if manual_goals.values.any?(&:present?)
      # If the user provided manual goals, keep those and skip automatic calculation
      save!
    else
      calculate_goals!
    end
  end

  def calculate_goals!
    return save! unless ready_for_goal_calculation?

    update!(build_daily_goals)
  end

  def remaining_macros_for_today
    consumed = todays_logs_macros
    {
      calories: [ daily_calories_goal.to_i - consumed[:calories], 0 ].max,
      protein_g: [ daily_protein_goal_g.to_i - consumed[:protein_g], 0 ].max,
      fats_g: [ daily_fats_goal_g.to_i - consumed[:fats_g], 0 ].max,
      carbs_g: [ daily_carbs_goal_g.to_i - consumed[:carbs_g], 0 ].max
    }
  end

  def todays_food_logs
    food_logs.with_attached_photo.where(created_at: Time.zone.today.all_day)
  end

  private

  def ready_for_goal_calculation?
    weight_kg.present? && height_cm.present? && date_of_birth.present? && sex.present?
  end

  def age_in_years
    return 0 unless date_of_birth.present?

    now = Time.zone.today
    age = now.year - date_of_birth.year
    had_birthday = (now.month > date_of_birth.month) ||
                   (now.month == date_of_birth.month && now.day >= date_of_birth.day)
    had_birthday ? age : age - 1
  end

  def activity_multiplier
    {
      "sedentary" => 1.2,
      "lightly_active" => 1.375,
      "moderately_active" => 1.55,
      "very_active" => 1.725,
      "extra_active" => 1.9
    }.fetch(activity_level, 1.2)
  end

  def goal_adjustment
    case goal_type
    when "lose" then -500
    when "gain" then 300
    else 0
    end
  end

  def calculated_daily_calories
    bmr =
      if sex == "male"
        10 * weight_kg + 6.25 * height_cm - 5 * age_in_years + 5
      else
        10 * weight_kg + 6.25 * height_cm - 5 * age_in_years - 161
      end

    ((bmr * activity_multiplier) + goal_adjustment).clamp(1_200, 4_000).round
  end

  def calculated_daily_protein
    multiplier = { "lose" => 2.0, "maintain" => 1.8, "gain" => 2.2 }.fetch(goal_type, 1.8)
    (weight_kg * multiplier).round
  end

  def calculated_daily_fats
    (weight_kg * 0.8).round
  end

  def calculated_daily_carbs(calories:, protein:, fats:)
    calories_from_protein = protein * 4
    calories_from_fat = fats * 9
    remaining_calories = calories - calories_from_protein - calories_from_fat
    [ (remaining_calories / 4.0).round, 0 ].max
  end

  def build_daily_goals
    calories = calculated_daily_calories
    protein = calculated_daily_protein
    fats = calculated_daily_fats

    {
      daily_calories_goal: calories,
      daily_protein_goal_g: protein,
      daily_fats_goal_g: fats,
      daily_carbs_goal_g: calculated_daily_carbs(calories:, protein:, fats:)
    }
  end

  def todays_logs_macros
    todays_food_logs.each_with_object({ calories: 0, protein_g: 0, fats_g: 0, carbs_g: 0 }) do |log, totals|
      totals[:calories] += log.calories.to_i
      totals[:protein_g] += log.protein_g.to_i
      totals[:fats_g] += log.fats_g.to_i
      totals[:carbs_g] += log.carbs_g.to_i
    end
  end

  def normalize_email_and_sex
    self.email = email&.downcase
    self.sex = sex&.downcase if sex.present?
  end
end
