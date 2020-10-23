class Cross
# The cross_data file has 6 columns:
  attr_accessor :parent1
  attr_accessor :parent2
  attr_accessor :f2_wild
  attr_accessor :f2_p1
  attr_accessor :f2_p2
  attr_accessor :f2_p1p2
  # Another property to link the Seed_stock object
  attr_accessor :seed_stock_id
  # A class variable to save the linked IDs
  @@linked=[]
  # Class variable that will contain all the stocks
  # It will allow us to do the Chi square test
  @@all_crosses=[]

  def initialize(params={})
    @parent1 = params.fetch(:parent1, "ABCD")
    @parent2 = params.fetch(:parent2, "ABCD")
    @f2_wild = params.fetch(:f2_wild, "000")
    @f2_p1 = params.fetch(:f2_p1, "000")
    @f2_p2 = params.fetch(:f2_p2, "000")
    @f2_p1p2 = params.fetch(:f2_p1p2, "000")
    @seed_stock1 = Seed_stock.get_stocks.find{|i| i.seed_stock == @parent1 }
    @seed_stock2 = Seed_stock.get_stocks.find{|i| i.seed_stock == @parent2 }
    @@all_crosses << self
  end
# To create the objects for this class (and the others) I use a class method:
  def Cross.get_data(file_path)
    File.readlines(file_path)[1..-1].each do |line| #Read the file lines and skip header
      p1, p2, f2w, f2p1, f2p2, f2p1p2 = line.strip.split("\t")
      Cross.new(:parent1 => p1, :parent2 => p2  , :f2_wild => f2w,  :f2_p1=> f2p1, :f2_p2 => f2p2, :f2_p1p2 => f2p1p2)
    end
  end
  
  def Cross.get_crosses
    return @@all_crosses
  end
  
  def Cross.chi2
    @@all_crosses.each {|e|  
      obs=[e.f2_wild,e.f2_p1,e.f2_p2,e.f2_p1p2].flatten.map{|x| x.to_f}
      total=obs.sum
      puts total
      exp=[9,3,3,1].map{|x| x*(total/16)}
      puts exp
      puts obs
      rest= (obs - exp)
      puts rest
      chi= [([rest].map{|x| x**2})/exp].sum
      # For all dihybrid crosses, the degree of freedom should be: (number of phenotypes – 1)
      # Since we have 4 phenotypes, df=3
      # When df = 3, a value > 7.815 means results are statistically significant (p < 0.05)
      # If results are statistically significant the genes are linked
      # source= https://ib.bioninja.com.au/higher-level/topic-10-genetics-and-evolu/102-inheritance/chi-squared-test.html
      if chi>7.815
        puts "#{e.seed_stock1.gene.gene_name} is linked to #{e.seed_stock2.gene.gene_name} with Chisquare score: #{chi}."
        
      end
    }
    
  end 
end