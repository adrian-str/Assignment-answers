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
  @genes=Hash.new
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

  repf=(Bio::Sequence::NA.new("CTTCTT"))#.to_re
  repr=(Bio::Sequence::NA.new("AAGAAG"))#.to_re
  @bioseq=Hash.new
  
  genes.each do |code,embl|
    added=[]
    bio_seq=embl.to_biosequence
    embl.features do |feature|
      next unless feature.feature == "exon"
      
      feature.locations.each do |location|
        
        exon_seq=embl.seq[location.from..location.to]
        next if exon_seq.nil?
        if location.strand == 1
          if exon_seq.match(repf)
            positionf = [exon_seq.match(repf).begin(0)+1,exon_seq.match(repf).end(0)].join('..')
            bio_seq.features << add_features("#{positionf}",location.strand) unless added.include?(positionf) #don't add same feature more than once
            added << positionf 
          end
        elsif location.strand == -1
          if exon_seq.match(repr)
            positionr = [exon_seq.match(repr).begin(0),exon_seq.match(repr).end(0)-1].join('..')
            bio_seq.features << add_features("complement(#{positionr})",location.strand) unless added.include?(positionr)
            added << positionr
          end
        @bioseq[code]=bio_seq   
        end
      end
    end
  end
end

def add_features(pos,strand)
  ft=Bio::Feature.new('myrepeat',pos)
  ft.append(Bio::Feature::Qualifier.new('repeat_motif','cttctt'))
  ft.append(Bio::Feature::Qualifier.new('function','insertion site'))
  if strand == 1
		ft.append(Bio::Feature::Qualifier.new('strand', '+'))
  elsif strand == -1
		ft.append(Bio::Feature::Qualifier.new('strand', '-'))
  end
end

def write_gff3_genes(bioseq,source="BioRuby",type="direct_repeat",score=".",phase=".")
  
  File.open('genes_report.gff3', 'w+') do |g|
    g.puts("##gff-version 3")
    @bioseq.each do |code,bio_seq|
      counts=0
      bio_seq.features.each do |feature|
        next unless feature.feature == 'myrepeat'
        counts+=1
        pos=feature.locations.first 
        strand=feature.assoc['strand']
        attributes="ID=CTTCTT_insertional_repeat_#{code}_#{counts};"
        g.puts("#{code}\t#{source}\t#{type}\t#{pos.from}\t#{pos.to}\t#{score}\t#{strand}\t#{phase}\t#{attributes}")
      end
    end
  end
end

def write_gff3_chr(bioseq,source="BioRuby",type="direct_repeat",score=".",phase=".")
  
  File.open('chr_report.gff3', 'w+') do |c|
   c.puts("##gff-version 3")
   # chromosome:TAIR10:3:20119140:20121314:1 (primary accession)
    @bioseq.each do |code,bio_seq|
      chr_coords=bio_seq.primary_accession.split(":")[3]
      seqid=bio_seq.entry_id.strip
      counts=0
      bio_seq.features.each do |feature|
        next unless feature.feature == 'myrepeat'
        counts+=1
        pos=feature.locations.first
        strand=feature.assoc['strand']
        attributes="ID=CTTCTT_insertional_repeat_#{code}_#{counts};"
        first=chr_coords.to_i+pos.from
        last=chr_coords.to_i+pos.to
        c.puts("#{seqid}\t#{source}\t#{type}\t#{first}\t#{last}\t#{score}\t#{strand}\t#{phase}\t#{attributes}")
      end
    end
  end
end

def noreps_report(genes,bioseq)
  count=0
  File.open('loci_without_repeats.txt', 'w+') do |r|
    r.puts("The following loci contain no CTTCTT repeats:")
    genes.each do |k,v|
      unless bioseq.keys.include?(k)
        count+=1
        r.puts("\t#{count} : #{k}")
      end
    end
  end
end




puts "Starting to compute..."
puts "This should take around 2 minutes"
get_embl(ARGV[0])

scan_exons(@genes)

puts "Searching for the repeats and adding features"

write_gff3_genes(@bioseq)

puts "Writing GFF3 file with gene coordinates"

write_gff3_chr(@bioseq)

puts "Writing GFF3 file with chromosomes coordinates"

noreps_report(@genes,@bioseq)

puts "Created report with genes that don't have CTTCTT repeat"
