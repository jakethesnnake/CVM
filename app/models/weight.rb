class Weight < ApplicationRecord
  belongs_to :organ
  belongs_to :animal
  
  validates :mean, numericality: true, allow_blank: true
  validates :standard_deviation, numericality: true, allow_blank: true
  validates :sample_size, numericality: true, allow_blank: true
  validates :number_of_studies, numericality: true, allow_blank: true

  before_validation :set_defaults
  after_create :add_list

  # <TEMP>
  def add_list
    return unless reference_string
    num_arr = reference_string.split(/,/)
    return unless num_arr && num_arr.count > 0
    arr = num_arr.map { |n| n.to_i }
    Weight.find_by_id(id).add_reference_number_list(arr)
  end

  def publications
    sets = WeightPublication.where(weight_id: id)
    return [] unless sets.count > 0
    pubs = []
    sets.each do |set|
      pubs << Publication.find_by_id(set.publication_id)
    end
    pubs
  end

  def organ_name
    Organ.find_by_id(organ_id).name
  end

  # <TEST>
  def add_reference_number_list(num_list)
    raise Exception unless num_list.count > 0
    num_list.each do |num|
      pub = Publication.find_by_reference_number(num)
      raise Exception unless pub.is_a?(Publication)
      add_publication(pub)
    end
  end

  # <TEST>
  def all_reference_numbers
    return [] unless publications.count > 0
    nums = []
    publications.each { |publication| nums << publication.reference_number }
    nums
  end

  def add_publication(publication)
    return unless publication.is_a?(Publication)
    WeightPublication.find_or_create_by!(weight_id: id, publication_id: publication.id)
  end

  def get_reference_link_list
    weight_pubs = WeightPublication.where(weight_id: id)
    return [] unless weight_pubs.count > 0
    nums = []
    weight_pubs.each do |weight_pub|
      pub = Publication.find_by_id(weight_pub.publication_id)
      ref_num = pub.reference_number
      nums << ref_num
    end
    nums
  end

  private
    # Private: sets default values
    def set_defaults
      self.parameter_id ||= 1
    end
end
