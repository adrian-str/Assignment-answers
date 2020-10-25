class Cross
# The cross_data file has 6 columns:
  attr_accessor :parent1
  attr_accessor :parent2
  attr_accessor :f2_wild
  attr_accessor :f2_p1
  attr_accessor :f2_p2
  attr_accessor :f2_p1p2
  # Another two properties to link the Seed_stock object with each parent
  attr_accessor :seed_stock1
  attr_accessor :seed_stock2
  # Class variable that will contain all the stocks
  # It will allow doing the Chi square test
  @@all_crosses=[] 

  def initialize(params={})
    @parent1 = params.fetch(:parent1, "ABCD")
    @parent2 = params.fetch(:parent2, "ABCD")
    @f2_wild = params.fetch(:f2_wild, "000")
    @f2_p1 = params.fetch(:f2_p1, "000")
    @f2_p2 = params.fetch(:f2_p2, "000")
    @f2_p1p2 = params.fetch(:f2_p1p2, "000")
    @seed_stock1 = Seed_stock.get_stocks.find{|i| i.seed_stock == @parent1 } # We need to link each parent in order to get both linked genes later
    @seed_stock2 = Seed_stock.get_stocks.find{|i| i.seed_stock == @parent2 }
    @@all_crosses << self # save everything in this list
  end
# To create the objects for this class (and the others) I use a class method:
  def Cross.get_data(file_path)
    File.readlines(file_path)[1..-1].each do |line| #Read the file lines and skip header
      p1, p2, f2w, f2p1, f2p2, f2p1p2 = line.strip.split("\t") #strip the lines of newlines' (\n), separate values by tab, and save them in the different instance var 
      Cross.new(:parent1 => p1, :parent2 => p2  , :f2_wild => f2w,  :f2_p1=> f2p1, :f2_p2 => f2p2, :f2_p1p2 => f2p1p2)
      
    end
    
  end
  
  def Cross.get_crosses # Class method to access all the objects
    return @@all_crosses
    
  end
  
  def Cross.chi2
    Cross.get_crosses.select {|e|  
      obs=[e.f2_wild,e.f2_p1,e.f2_p2,e.f2_p1p2].map{|x| x.to_f}
      total=obs.sum
      exp=[9,3,3,1].map{|x| x*(total/16)}
      rest= [obs[0]-exp[0],obs[1]-exp[1],obs[2]-exp[2],obs[3]-exp[3]].map! {|x| x**2}
      div= [rest[0]/exp[0],rest[1]/exp[1],rest[2]/exp[2],rest[3]/exp[3]]
      chi= div.sum
      
      # For all dihybrid crosses, the degree of freedom should be: (number of phenotypes – 1)
      # Since we have 4 phenotypes, df=3
      # When df = 3, a value > 7.815 means results are statistically significant (p < 0.05)
      # If results are statistically significant the genes are (probably) linked 
      # source = https://ib.bioninja.com.au/higher-level/topic-10-genetics-and-evolu/102-inheritance/chi-squared-test.html
      if chi>7.815
        puts "Recording: #{e.seed_stock1.gene.gene_name} is genetically linked to #{e.seed_stock2.gene.gene_name} with Chisquare score: #{chi}."
        e.seed_stock1.gene.linked_to=e.seed_stock2.gene.gene_name #adding the links as a property of each linked gene
        e.seed_stock2.gene.linked_to=e.seed_stock1.gene.gene_name
        puts
      end
    }
    
  end 
end