class Animal < ApplicationRecord
  validates :name, presence: true
  validates :parent_id, presence: true, numericality: true, allow_blank: true

  validate :valid_or_nil_parent

  # Public: returns parameters that animal has data for
  #
  # returns [] unless data exists
  def parameters
    Parameter.all.select { |p| has_parameter_data?(p) }
  end

  # Public: returns animal parent or nil otherwise
  def parent
    Animal.find_by_id(parent_id)
  end

  # Public: returns all organs for animal (that has an associated weight)
  def organs
    weights = organ_weights
    return [] unless weights.count > 0
    organs = []
    weights.each do |weight|
      organ = Organ.find_by_id(weight.organ_id)
      organs << organ
    end
    organs
  end

  # Public: returns true if organ has parent
  def is_child?
    parent_id.present?
  end

  # Public: returns all organ weights for animal
  def organ_weights
    Weight.where(animal_id: id)
  end

  # Public: returns all organ weights that correspond to the animal AND
  # are included in the parameter set
  # <TEST>
  def filtered_weights(filter_organs, parameter)
    final = []
    return final unless parameter.is_a?(Parameter) && filter_organs &&
        filter_organs.count > 0 && weights_for_parameter(parameter).count > 0
    weights_for_parameter(parameter).each do |weight|
      organ = Organ.find_by_id(weight.organ_id)
      final << weight if filter_organs.include?(organ)
    end
    final
  end

  # Public: returns ordered list of animals
  def self.ordered
    arr = []
    ord = [21,10,2,8,9,6,7,3,4,5,11,12,13,14,15,16,17,22,23,24,25,26,27,28,29]

    ord.each do |num|
      arr << Animal.find_by_id(num)
    end
    arr
  end

  # Public: returns sorted table of animals
  #
  # from parents -> children -> grandchildren
  def self.sort_animal_list(animals, sorted_arr = Array.new)
    return sorted_arr unless animals && animals.count > 0
    next_parent = animals.detect { |a| a.parent_id.nil? || a.parent && !animals.include?(a.parent) }

    raise Exception unless next_parent

    sorted_arr << animals.delete(next_parent)
    children = animals.select{ |c| c.parent == next_parent }

    return sort_animal_list(animals, sorted_arr) if children.count == 0

    children.each do |child|
      sorted_arr << animals.delete(child)
      grandchildren = animals.select{ |c| c.parent == child }
      next unless grandchildren.count > 0
      grandchildren.each do |grandchild|
        sorted_arr << animals.delete(grandchild)
      end
    end

    sort_animal_list(animals, sorted_arr)
  end

  # Public: returns (ordered set of) self and descendants
  # from perspective of parent or grandparent
  #
  # if no children, returns self only
  def self_and_descendants
    arr = [self]
    return arr unless children.count > 0
    children.each do |child|
      arr << child
      next unless child.children.count > 0
      child.children.each { |grandchild| arr << grandchild }
    end
    arr
  end

  # Public: returns children for animal
  def children
    Animal.where(parent_id: id)
  end

  # Public: returns all weights associated with a given parameter
  def weights_for_parameter(parameter)
    return unless parameter.is_a?(Parameter)
    Weight.where(animal_id: id, parameter_id: parameter.id)
  end

  # Public: returns all organs associated with a given parameter
  #
  # returns [] if none present or if parameter invalid
  def organs_for_parameter(parameter)
    return unless parameter.is_a?(Parameter)
    organs = []
    Weight.where(animal_id: id, parameter_id: parameter.id).each do |weight|
      org = Organ.find_by_id(weight.organ_id)
      organs << org unless organs.include?(org)
    end
    organs
  end

  # Public: returns all hemat data for animal, if it exists
  #
  # returns [] otherwise
  def hemat_data
    Weight.where(animal_id: id, parameter_id: 5)
  end

  # Public: returns true if the animal has data for a given parameter
  #
  # returns false otherwise
  def has_parameter_data?(parameter)
    return unless parameter.is_a?(Parameter)
    weights = weights_for_parameter(parameter)
    weights.count > 0
  end

  # Public: returns true if the animal has "range" data for this parameter
  #
  # returns false otherwise
  def has_range_info?(parameter)
    return unless parameter.is_a?(Parameter)

    Weight.where(animal_id: id, parameter_id: parameter.id).each do |weight|
      return true if weight.range
    end

    false
  end

  private
    # Private: ensures parent_id is nil or valid
    def valid_or_nil_parent
      errors[:parent_id] << 'Invalid Parent ID provided' unless parent_id.nil? ||
          Animal.exists?(id: parent_id.to_i)
    end
end
