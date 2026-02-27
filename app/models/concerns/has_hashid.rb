module HasHashid
  extend ActiveSupport::Concern

  included do
    before_validation :generate_hashid, on: :create
    attr_readonly :hashid
    validates :hashid, presence: true, uniqueness: true
  end

  def to_param
    hashid
  end

  private

  def generate_hashid
    return if hashid.present?
    loop do
      candidate = "#{SecureRandom.alphanumeric(8)}-#{name.to_s.parameterize}"
      break self.hashid = candidate unless self.class.unscoped.exists?(hashid: candidate)
    end
  end
end
