class Cross
# The cross_data file has 6 columns:
  attr_accessor :parent1
  attr_accessor :parent2
  attr_accessor :f2_wild
  attr_accessor :f2_p1
  attr_accessor :f2_p2
  attr_accessor :f2_p1p2

  def initialize(params={})
    @parent1 = params.fetch(:parent1, "ABCD")
    @parent2 = params.fetch(:parent2, "ABCD")
    @f2_wild = params.fetch(:f2_wild, "000")
    @f2_p1 = params.fetch(:f2_p1, "000")
    @f2_p2 = params.fetch(:f2_p2, "000")
    @f2_p1p2 = params.fetch(:f2_p1p2, "000")
  end
# To create the objects for this class (and the others) I use a class method:
  def Cross.get_data(file_path)
    
  
  end
end