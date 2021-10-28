class Group < ApplicationRecord
  validates :group_id, uniqueness: true
end
