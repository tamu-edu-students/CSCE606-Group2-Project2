class FoodLog < ApplicationRecord
  belongs_to :user

  has_one_attached :photo

  validates :food_name, presence: true
  validates :calories, :protein_g, :fats_g, :carbs_g,
            numericality: { greater_than_or_equal_to: 0, allow_nil: false }

  scope :for_date, ->(date) { where(created_at: date.all_day) }

  def macros
    {
      calories: calories.to_i,
      protein_g: protein_g.to_i,
      fats_g: fats_g.to_i,
      carbs_g: carbs_g.to_i
    }
  end
end
