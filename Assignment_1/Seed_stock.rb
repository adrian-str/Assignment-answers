class Seed_stock
# The seed_stock_data file has 5 columns:
  attr_accessor :seed_stock
  attr_accessor :id
  attr_accessor :last_planted
  attr_accessor :storage
  attr_accessor :grams
# Another property to link the Gene object
  attr_accessor :gene
# Class variable that will contain all the genes
# it will allow us to link with Cross object
  @@all_stocks= []
  
  def initialize(params= {})
    @seed_stock = params.fetch(:seed_stock, "X00")
    @id = params.fetch(:id,"AT0G0000")
    @last_planted = params.fetch(:last_planted, "missing date")
    @storage = params.fetch(:storage, "unknown location")
    @grams = params.fetch(:grams, 0)
    @gene = Gene.get_genes.find{|i| i.gene_ID == @id }
    @@all_stocks << self
  end
  # To create the objects for this class (and the others) I use a class method:
  def Seed_stock.load_from_file(file_path)
    File.readlines(file_path)[1..-1].each do |line| #Read the file lines and skip header
      stock, gene_id, last, place, g = line.strip.split("\t")
      Seed_stock.new(:seed_stock => stock, :id => gene_id  , :last_planted => last,  :storage=> place, :grams => g)
      
    end
  end
  
  def Seed_stock.get_stocks
    return @@all_stocks
    
  end
  
  def Seed_stock.plant(number)
    @grams= @grams.to_i
    @grams= @grams-number.to_i
    @last_planted= Time.now.strftime('%-d/%-m/%Y')
    if @grams <= 0
      @grams = 0
      puts ""
        #code
    end
    
    
  
end