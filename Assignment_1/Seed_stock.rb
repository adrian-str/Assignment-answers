class Seed_stock
# The seed_stock_data file has 5 columns:
  attr_accessor :seed_stock
  attr_accessor :id
  attr_accessor :last_planted
  attr_accessor :storage
  attr_accessor :grams
# Another property to link the Gene object
  attr_accessor :gene
# Class variable that will contain all the stocks
# it will allow linking with Cross object
  @@all_stocks= []
  
  def initialize(params= {})
    @seed_stock = params.fetch(:seed_stock, "X00")
    @id = params.fetch(:id,"AT0G0000")
    @last_planted = params.fetch(:last_planted, "missing date")
    @storage = params.fetch(:storage, "unknown location")
    @grams = params.fetch(:grams, 0)
    @gene = Gene.get_all.find{|i| i.gene_ID == @id }
    @@all_stocks << self # save everything in this list
  end
  # To create the objects for this class (and the others) I use a class method:
  def Seed_stock.load_from_file(path)
    f=File.open(path, "r")
    @header=f.readline #save the header for later
    f.each_line do |line| #Read the rest of the file lines
      stock, gene_id, last, place, g = line.strip.split("\t") #strip the lines of newlines' (\n), separate values by tab, and save them in the different instance var 
      Seed_stock.new(:seed_stock => stock, :id => gene_id  , :last_planted => last,  :storage=> place, :grams => g)
      
    end
    f.close
  end
  
  def Seed_stock.get_stocks # Class method to access all the objects
    return @@all_stocks
    
  end
  
  def Seed_stock.plant(number)
    Seed_stock.get_stocks.select {|s|
    s.grams= s.grams.to_i-number
    s.last_planted = Time.now.strftime('%-d/%-m/%Y')
    if s.grams <= 0
      s.grams = 0 #there can't be a negative amount of grams
      puts "WARNING: we have run out of Seed stock #{s.seed_stock}"

    end}
  end
  
  def Seed_stock.write_database(new)
    file=File.open(new,'w')
    file.write(@header) #printing the header and then each row
    @@all_stocks.each do |row|
      file.write("#{row.seed_stock}\t#{row.id}\t#{row.last_planted}\t#{row.storage}\t#{row.grams.to_i}\n")
    end
    file.close
  end
  
  def Seed_stock.get_seed_stock(id)
     if Seed_stock.get_stocks.find {|o| o.seed_stock==id}
       f=Seed_stock.get_stocks.find {|o| o.seed_stock==id}
       puts ("ID: "+f.seed_stock+"; Gene ID: "+f.id+"; Last planted: "+f.last_planted+"; Storage: "+f.storage+"; Grams: "+f.grams.to_s+"; Gene name: "+f.gene.gene_name+"")
     else
       puts "Stock ID (#{id}) not found."
     end
     
  end
  
end