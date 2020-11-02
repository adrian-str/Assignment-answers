require 'rest-client'

class InteractionNetwork
  
  attr_accessor :network
  attr_accessor :members
  attr_accessor :kegg_path
  attr_accessor :go_terms
  
  
  def initialize(params={})
    @network = params.fetch(:network,0)
    @members = params.fetch(:members,'NA')
    @kegg_path = params.fetch(:kegg_path,'NA')
    @go_terms = params.fetch(:go_terms,'NA')
  end
  
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
   
  
  def self.search_interactors(file)
        @intact=Hash.new
        File.open(file).each do |code|
          
          res = fetch("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{code.strip}%20AND%20species:arath/?format=tab25")
          @intact[code.strip]=res.body.split("\n")
           
    end
    
  end
  
  def self.search_ppi(intact, cutv=0.485)
    @genes=intact.keys
    
    score=/i\w+-\w+:(0\.\d+)/
    intact.each do |a,int|
      int.each do |i|
        g1,g2=i.scan(/A[T]\d[G]\d\d\d\d\d/)
        score=i.match(score)[1].to_f
        next if score<=cutv
        if @genes===g1||@genes===g2
          
            #code
        end
        
        
      end
    end
    end
  end
end