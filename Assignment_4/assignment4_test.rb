## Assignment 4
require 'bio'
arath=ARGV[0]
spomb=ARGV[1]
unless arath && spomb 
  abort "run this using the command\n ruby assignment4_test.rb ./databases/arath.fa ./databases/spombe.fa"
end
araf=Bio::FlatFile.auto(arath)
spof=Bio::FlatFile.auto(spomb)

def db_type(flatfasta)
 entry=Bio::Sequence.auto(flatfasta.next_entry.to_s).guess
  if entry==Bio::Sequence::NA
    type='nucl'
  elsif entry == Bio::Sequence::AA
    type='prot'
  end
  return type
end

def make_db(flatfasta,fasta)
 type=db_type(flatfasta)
 system("makeblastdb -in #{fasta} -dbtype '#{type}' -out $(dirname #{fasta})/$(basename #{fasta} .fa)")
end

def blast(db,query,type)
 eval='-e 1e-6' #source: https://doi.org/10.1371/journal.pone.0101850
 factory=Bio::Blast.local("#{type}","#{File.dirname(db)}/#{File.basename(db,".fa")}","-F 'm S' #{eval}" ) #source (-F): https://doi.org/10.1093/bioinformatics/btm585
 report=factory.query(query)
 if report.hits[0]
  return report.hits[0].definition.split("|")[0].strip
 end
end

def blast_type(flat,queries) #only added the types needed for the assignment
  if db_type(flat)=='prot' and db_type(queries)=='nucl'
    type='blastx'
  elsif db_type(flat)=='nucl' and db_type(queries)=='prot'
    type='tblastn'
  end
 return type
end

def get_besthit(db,flat,queries)
 besthit=Hash.new
 type=blast_type(flat,queries)
 count=0
  queries.each_entry do |query|
   puts "Using query: #{query.entry_id}"
   besthit[query.entry_id]=blast(db,query,type)
   break if count==100
   count+=1
  end
 return besthit
end

def get_orthologues(db1,db2,flat1,flat2)
 orthologues=Hash.new
 puts "Searching for reciprocal best hits..."
 besthits=get_besthit(db1,flat1,flat2)
 flat1.each_entry do |entry|
  next unless besthits.value?(entry.entry_id)
  reciprocalhits=blast(db2,entry,blast_type(flat2,flat1))
   if besthits[reciprocalhits]==entry.entry_id
    orthologues[reciprocalhits]=entry.entry_id
   end
  end
  return orthologues 
end

make_db(spof,spomb)
make_db(araf,arath)
#get_besthit(arath,araf,spof)
orthologues=get_orthologues(arath,spomb,araf,spof)


 puts "Pairs of possible orthologues:"
 orthologues.each do |k,v|
  puts "\t- #{k} and #{v}"
 end
