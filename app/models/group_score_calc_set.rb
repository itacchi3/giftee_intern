class GroupScoreCalcSet < ApplicationRecord
  validates :group_id, uniqueness: true
end
