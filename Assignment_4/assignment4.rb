## Assignment 4
require 'bio'
arath=ARGV[0]
spomb=ARGV[1]
araf=Bio::FlatFile.auto(arath)
spof=Bio::FlatFile.auto(spomb)
puts araf.class
puts spof.class
def get_type(file)
 entry=Bio::Sequence.auto(file.next_entry.to_s).guess
 
  if entry==Bio::Sequence::NA
    type='nucl'
  elsif entry == Bio::Sequence::AA
    type='prot'
  end
  return type
end

def make_db(flatfile,file)
 type=get_type(flatfile)
 p type
  system("cd databases")
  system("makeblastdb -in #{file} -dbtype '#{type}' -out $basename#{file}")
  
    
end

make_db(spof,spomb)
make_db(araf,arath)