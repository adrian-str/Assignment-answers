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
  
  def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="")
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
   
  def self.get_agi(file)
    @@genes=[]
    File.open(file).each do |code|
      @@genes << code
    end
    return @@genes
  end
  
  @counter=0
  def self.search_interactors(genes)
    @counter=+1
    @interacts=Hash.new    
    if genes.is_a?(Array)
      genes.each do |code|
        res = fetch("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{code}%20AND%20species:arath/?format=tab25")
        score=/i\w+-\w+:(0\.\d+)/
        if res
          intact=res.body.split("\n")
          intact.each do |int|
            g1=int.match(/(A[T]\d[G]\d\d\d\d\d)\(locus\sname\)/)[1]
            score=int.match(score)[1].to_f
            next if score<=cutv
            if @@genes===g1
              @interacts[code]=g1
            else
              search_interactors(g1)
              
            end
          end
        end
      end
    end 
  end
  

  

        
        
      
    
  
end