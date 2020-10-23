puts "\nASSIGNMENT 1\n"
puts
puts "Getting the Classes..."
require './GenesClass'
require './Seed_stock'
require './Cross'

gpath="./"+ARGV[0]+""
spath="./"+ARGV[1]+""
cpath="./"+ARGV[2]+""
upath=""+ARGV[3]+""
puts "\nLoading the data...\n"
Gene.get_genes(gpath)
Seed_stock.load_from_file(spath)
Cross.get_data(cpath)

puts "\n Task #1\n"
puts "\Planting 7 grams of each record:\n\n"
Seed_stock.plant(7)
puts "\nPlanted!"
puts "\nCreating new file with the actual state of the genenbank..."
puts "Let's have a look at a couple of lines:\n\n"
Seed_stock.write_database(upath)
File.readlines(upath)[0..2].each do |line|
  print line
end
puts "\nGreat success!"

puts "\n Task #2"
puts "\nChecking which genes are linked with Chi-square test"
puts "...and adding them as a property of each linked gene:\n\n"
Cross.chi2
puts "\nFinal Report:\n\n"
Gene.get_links
puts "\n****************************"
puts "\nBONUS"
puts "\n1.Let's load some gene data with an incorrect identifier:\n\n"
Gene.get_genes("./gene_incorrect.tsv")

puts "\n2.Acces to individual of Seed_stock objects based on their ID:\n"
puts "\nCorrect ID #1:\n\n"
Seed_stock.get_seed_stock("A334")
puts "\nCorrect ID #2:\n\n"
Seed_stock.get_seed_stock("B52")
puts "\nWrong ID:\n\n"
Seed_stock.get_seed_stock("X334")