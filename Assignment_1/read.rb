require "csv"
seed_stock = CSV.read("./StockDatabaseFiles/seed_stock_data.tsv", { :col_sep => "\t" },{:headers=> true})
puts seed_stock

