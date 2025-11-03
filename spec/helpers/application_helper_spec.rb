require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#next_direction_for_sort' do
    it 'returns desc when switching from asc' do
      expect(helper.next_direction_for_sort('calories', 'asc', 'calories')).to eq('desc')
    end

    it 'returns asc when switching from desc' do
      expect(helper.next_direction_for_sort('calories', 'desc', 'calories')).to eq('asc')
    end

    it 'returns default desc when column changes' do
      expect(helper.next_direction_for_sort('calories', 'asc', 'created_at')).to eq('desc')
    end
  end

  describe '#history_sort_link' do
    it 'renders a link with sort params and no indicator when not active' do
      link = helper.history_sort_link('Date', 'created_at', nil, nil)
  expect(link).to include('Date')
  expect(link).to match(/href="\/food_logs[^"]*sort=created_at/)
  expect(link).not_to include('▲')
  expect(link).not_to include('▼')
    end

    it 'adds an indicator when the column is active' do
      link = helper.history_sort_link('Calories', 'calories', 'calories', 'asc')
      expect(link).to include('Calories')
      expect(link).to include('▲')
    end
  end
end
