class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  enum role: [ :pcv, :pcmo, :admin ]

  belongs_to :country
  has_many :orders, dependent: :destroy

  has_many :phone_numbers, dependent: :destroy
  accepts_nested_attributes_for :phone_numbers, allow_destroy: true

  validates_presence_of :country, :location, :first_name, :last_name, :role
  validates_presence_of :pcv_id, :if => :pcv?
  validates :pcv_id, uniqueness: true, :if => :pcv?
  validates :time_zone, inclusion: {in: ActiveSupport::TimeZone.all.map(&:name) }

  def self.find_by_pcv_id str
    where(['lower(pcv_id) = ?', str.downcase]).first!
  end

  def self.find_by_phone_number number
    PhoneNumber.lookup(number).user
  end

  def primary_phone
    @_primary_phone ||= phone_numbers.first
  end

  def self.pcmos_by_country
    pcmo.includes(:country).group_by &:country
  end

  # TODO: should this be a default scope? Can those inspect current_user?
  def accessible model
    if admin?
      model.all
    elsif pcmo?
      model.where(country_id: country_id)
    else
      model.where(user_id: id)
    end
  end

  def send_reset_password_instructions opts={}
    MailerJob.enqueue :forgotten_password, id
  end

  def name
    "#{first_name} #{last_name}".strip
  end
end
