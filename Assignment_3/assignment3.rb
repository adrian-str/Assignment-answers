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
        genes[id]=embl
      end
    end
  return genes
end

sequence = Bio::Sequence.auto("AAAACCTCCTAGAGGGAGGAGGAGGAAAAA")
sequence.output(:embl)