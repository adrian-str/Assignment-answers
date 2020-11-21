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
  genes=Hash.new
    File.open(file).each do |code|
      code.strip!
      response = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{code}")
      if response
        embl=Bio::EMBL.new(response.body)
        genes[code]=embl
      end
    end
  return genes
end

#sequence = Bio::Sequence.auto("AAAACTTCTTAGAGGGAAGAAGAGGAAAAA")
#seq_embl=sequence.output(:embl)

def scan_exons(genes)
  repf= Bio::Sequence.auto("CTTCTT")
  repr=repf.reverse_complement
  genes.each_value do |embl|
    bio_seq=embl.to_biosequence
    next unless embl.seq.match(repf) or embl.seq.match(repr)
    embl.features do |feature|
      next unless feature.feature == "exon"
      feature.locations.each do |location|
        exon_seq=embl.seq[location.from..location.to]
        if location.strand == 1
          if exon_seq.match(repf)
            positionf = [exon_seq.match(repf).begin(0),exon_seq.match(repf).end(0)].join('..')
            bio_seq.features << add_features(positionf,location.strand)
          end
        elsif location.strand == -1
          if exon_seq.match(repr)
            positionr = [exon_seq.match(repr).begin(0),exon_seq.match(repr).end(0)].join('..')
            bio_seq.features << add_features(positionr,location.strand)
          end
        end
        
      end
    end
  end
end

def add_features(pos,strand)
  ft=Bio::Feature.new('repeat',pos)
  ft.append(Bio::Feature::Qualifier.new('repeat','cttctt'))
  ft.append(Bio::Feature::Qualifier.new('function','insertion site'))
  if strand == 1
		f.append(Bio::Feature::Qualifier.new('strand', '+'))
	elsif strand == -1
		f.append(Bio::Feature::Qualifier.new('strand', '-'))
  end
  
end  
  