## Assignment 3
require 'bio'
require 'rest-client'

def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
    response = RestClient::Request.execute({
      method: :get,
      url: url.to_s,
      user: user,
      password: pass,
      headers: headers})
    return response
    
    rescue RestClient::ExceptionWithResponse => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue RestClient::Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
end

def get_embl(file)
  @genes=Hash.new #instance variable hash to save the AGI Loci codes and their EMBL entries
    File.open(file).each do |code|
      code.strip!
      response = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{code}")
      if response
        embl=Bio::EMBL.new(response.body)
        @genes[code]=embl
      end
    end
  return @genes
end

def scan_exons(genes)

  repf=(Bio::Sequence::NA.new("CTTCTT")).to_re # pattern searched for on the + strand
  repr=(Bio::Sequence::NA.new("AAGAAG")).to_re # pattern searched for on the - strand
  @bioseq=Hash.new # instance variable hash to save the AGI Loci codes and their Sequence entries
  
  genes.each do |code,embl|
    added=[] # local variable to keep track of added positions on each gene
    bio_seq=embl.to_biosequence
    embl.features do |feature|
      next unless feature.feature == "exon"
      
      feature.locations.each do |location|
        
        exon_seq=embl.seq[location.from..location.to]
        next if exon_seq.nil?
        if location.strand == 1
          if exon_seq.match(repf)
            positionf = [exon_seq.match(repf).begin(0)+1,exon_seq.match(repf).end(0)].join('..')
            bio_seq.features << add_features("#{positionf}",location.strand) unless added.include?(positionf) # don't add same feature more than once
            @bioseq[code]=bio_seq
            added << positionf 
          end
        elsif location.strand == -1
          if exon_seq.match(repr)
            positionr = [exon_seq.match(repr).begin(0),exon_seq.match(repr).end(0)-1].join('..')
            bio_seq.features << add_features("complement(#{positionr})",location.strand) unless added.include?(positionr)
            @bioseq[code]=bio_seq
            added << positionr
          end
        end
      end
    end
  end
end

def add_features(pos,strand) # method implemented above to add new features to the Sequence entries
  ft=Bio::Feature.new('myrepeat',pos) # unique feature type and its location
  ft.append(Bio::Feature::Qualifier.new('repeat_motif','cttctt'))
  ft.append(Bio::Feature::Qualifier.new('function','insertion site'))
  if strand == 1
		ft.append(Bio::Feature::Qualifier.new('strand', '+'))
  elsif strand == -1
		ft.append(Bio::Feature::Qualifier.new('strand', '-'))
  end
end

def write_gff3_genes(bioseq,source="BioRuby",type="direct_repeat",score=".",phase=".")
  # method that takes the @bioseq instance variable to create the first gff3 report
  File.open('genes_report.gff3', 'w+') do |g|
    g.puts("##gff-version 3")
    @bioseq.each do |code,bio_seq|
      counts=0 # a counter to differentiate the repeats found in one gene
      bio_seq.features.each do |feature|
        next unless feature.feature == 'myrepeat' # select the features added before
        counts+=1
        pos=feature.locations.first # get the first Location object
        strand=feature.assoc['strand'] # get the strand qualifier
        attributes="ID=CTTCTT_insertional_repeat_#{code}_#{counts};" # add a different attribute for each feature
        g.puts("#{code}\t#{source}\t#{type}\t#{pos.from}\t#{pos.to}\t#{score}\t#{strand}\t#{phase}\t#{attributes}")
      end
    end
  end
end

def write_gff3_chr(bioseq,source="BioRuby",type="direct_repeat",score=".",phase=".")
  
  File.open('chr_report.gff3', 'w+') do |c|
   c.puts("##gff-version 3")
   # [0]chromosome:[1]TAIR10:[2]3:[3]20119140:20121314:1 (primary accession)
    @bioseq.each do |code,bio_seq|
      chr_coords=bio_seq.primary_accession.split(":")[3] # select the beginning position of the chromosome
      seqid=bio_seq.primary_accession.split(":")[2] # select the chromosome number
      counts=0
      bio_seq.features.each do |feature|
        next unless feature.feature == 'myrepeat'
        counts+=1
        pos=feature.locations.first
        strand=feature.assoc['strand']
        attributes="ID=CTTCTT_insertional_repeat_#{code}_#{counts};"
        first=chr_coords.to_i+pos.from # create the locations relative to the chromosome beginning position
        last=chr_coords.to_i+pos.to
        c.puts("#{seqid}\t#{source}\t#{type}\t#{first}\t#{last}\t#{score}\t#{strand}\t#{phase}\t#{attributes}")
      end
    end
  end
end

def noreps_report(genes,bioseq) # create a report of the loci for which no repeats have been found
  @count=0 # to count
  File.open('loci_without_repeats.txt', 'w+') do |r|
    r.puts("The following loci contain no CTTCTT repeats:")
    genes.each do |k,v|
      unless bioseq.keys.include?(k) # the loci codes that are not in the @bioseq variable are the ones for which the repeat has not been found
        @count+=1
        r.puts("\t#{@count} : #{k}")
      end
    end
  end
  return @count
end

# Script to develop the program
puts "Starting to compute..."
puts "This should take less than 5 minutes"
get_embl(ARGV[0])

scan_exons(@genes)

puts "Searching for the repeats and adding features"

write_gff3_genes(@bioseq)

puts "Writing GFF3 file with gene coordinates"

write_gff3_chr(@bioseq)

puts "Writing GFF3 file with chromosomes coordinates"

noreps_report(@genes,@bioseq)

puts "Created report with genes that don't have CTTCTT repeat (#{@count} genes)"
