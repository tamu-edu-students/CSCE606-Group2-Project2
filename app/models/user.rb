class User < ApplicationRecord
  has_many :food_logs, dependent: :destroy

  before_validation :normalize_email_and_sex
  after_save :recalculate_goals_if_needed

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
  validates :username, uniqueness: { case_sensitive: false }, allow_blank: true
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
      save!
    else
      calculate_goals!
    end
  end

  def calculate_goals!
    return save! unless ready_for_goal_calculation?

    goals = build_daily_goals

    validate_calculated_goals!(goals)
    update!(goals)
  end

    def needs_goal_recalculation?
    return false unless survey_completed?

    changes_affecting_goals = %w[weight_kg height_cm date_of_birth sex activity_level goal_type]
    (saved_changes.keys & changes_affecting_goals).any?
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

  def calories_balance_for_today
    daily_calories_goal.to_i - todays_logs_macros[:calories]
  end

  def over_calorie_limit?
    calories_balance_for_today <= 0
  end

  def todays_food_logs
    food_logs.with_attached_photo.where(created_at: Time.zone.today.all_day)
  end

  def calculation_breakdown
    return {} unless ready_for_goal_calculation?

    bmr = basal_metabolic_rate
    tdee = total_daily_energy_expenditure
    adjustment = goal_adjustment

    {
      age: age_in_years,
      bmr: bmr.round,
      activity_level: activity_level,
      activity_multiplier: activity_multiplier,
      tdee: tdee.round,
      goal_type: goal_type,
      goal_adjustment: adjustment,
      final_calories: (tdee + adjustment).clamp(1_200, 4_000).round,
      protein_multiplier: { "lose" => 2.0, "maintain" => 1.8, "gain" => 2.2 }.fetch(goal_type, 1.8),
      calculated_at: Time.zone.now
    }
  end

    def goals_comparison
    return {} unless ready_for_goal_calculation?

    fresh_goals = build_daily_goals

    {
      calories: {
        current: daily_calories_goal,
        calculated: fresh_goals[:daily_calories_goal],
        difference: fresh_goals[:daily_calories_goal].to_i - daily_calories_goal.to_i
      },
      protein: {
        current: daily_protein_goal_g,
        calculated: fresh_goals[:daily_protein_goal_g],
        difference: fresh_goals[:daily_protein_goal_g].to_i - daily_protein_goal_g.to_i
      },
      fats: {
        current: daily_fats_goal_g,
        calculated: fresh_goals[:daily_fats_goal_g],
        difference: fresh_goals[:daily_fats_goal_g].to_i - daily_fats_goal_g.to_i
      },
      carbs: {
        current: daily_carbs_goal_g,
        calculated: fresh_goals[:daily_carbs_goal_g],
        difference: fresh_goals[:daily_carbs_goal_g].to_i - daily_carbs_goal_g.to_i
      }
    }
  end

  private

  def ready_for_goal_calculation?
    weight_kg.present? && height_cm.present? && date_of_birth.present? && sex.present?
  end

  def validate_calculated_goals!(goals)
    if goals[:daily_calories_goal] < 1_200 || goals[:daily_calories_goal] > 4_000
      Rails.logger.warn "Calculated calories (#{goals[:daily_calories_goal]}) outside safe range"
    end

    if goals[:daily_protein_goal_g] < 50 || goals[:daily_protein_goal_g] > 400
      Rails.logger.warn "Calculated protein (#{goals[:daily_protein_goal_g]}g) outside typical range"
    end

    if goals[:daily_fats_goal_g] < 20 || goals[:daily_fats_goal_g] > 200
      Rails.logger.warn "Calculated fats (#{goals[:daily_fats_goal_g]}g) outside typical range"
    end

    if goals[:daily_carbs_goal_g] < 50 || goals[:daily_carbs_goal_g] > 600
      Rails.logger.warn "Calculated carbs (#{goals[:daily_carbs_goal_g]}g) outside typical range"
    end

    true
  end

  def age_in_years
    return 0 unless date_of_birth.present?

    now = Time.zone.today
    age = now.year - date_of_birth.year
    had_birthday = (now.month > date_of_birth.month) ||
                   (now.month == date_of_birth.month && now.day >= date_of_birth.day)
    calculated_age = had_birthday ? age : age - 1

    calculated_age.clamp(18, 100)
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

  def basal_metabolic_rate
    return 0 unless ready_for_goal_calculation?

    if sex == "male"
      10 * weight_kg + 6.25 * height_cm - 5 * age_in_years + 5
    else
      10 * weight_kg + 6.25 * height_cm - 5 * age_in_years - 161
    end
  end

  def total_daily_energy_expenditure
    basal_metabolic_rate * activity_multiplier
  end

  def calculated_daily_calories
    (total_daily_energy_expenditure + goal_adjustment).clamp(1_200, 4_000).round
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
    carbs = calculated_daily_carbs(calories:, protein:, fats:)

    Rails.logger.info "Calculated nutrition goals for user #{id}: " \
                      "Calories=#{calories}, Protein=#{protein}g, Fats=#{fats}g, Carbs=#{carbs}g " \
                      "(Age=#{age_in_years}, Weight=#{weight_kg}kg, Height=#{height_cm}cm, " \
                      "Activity=#{activity_level}, Goal=#{goal_type})"

    {
      daily_calories_goal: calories,
      daily_protein_goal_g: protein,
      daily_fats_goal_g: fats,
      daily_carbs_goal_g: carbs
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

  def recalculate_goals_if_needed
    return unless needs_goal_recalculation?

    Rails.logger.info "Auto-recalculating goals for user #{id} due to profile changes"
    calculate_goals!
  end
end
