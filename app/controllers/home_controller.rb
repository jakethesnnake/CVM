class HomeController < ApplicationController
  before_action :set_home, except: [:index]

  def index
    @animal = Animal.first
    @parameter = Parameter.first
    @organs = []
  end

  def filter
  end

  # NOT IMPLEMENTED
  def set_parameter
    raise Exception
  end

  def empty
    @organs = []
  end
  
  private
    # Private: assigns animal to default value (Animal.first)
    # OR id specified by parameter value
    def set_home
      @animal = Animal.find_by_id(params[:animal_id]) || Animal.first
      @parameter = Parameter.find_by_id(params[:parameter_id]) || Parameter.first

      if params[:organ_ids]
        @organs = Organ.organs_and_children_from_id_list(params[:organ_ids])
      else
        @organs = @animal.organs
      end
    end
end
