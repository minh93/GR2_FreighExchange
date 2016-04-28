class Invoice < ActiveRecord::Base
  belongs_to :request
  belongs_to :schedule
  belongs_to :supplier
end
