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
      @@genes << code.strip
    end
    
  end
  
  def self.get_interacting
    return @@interacting
  end
  
  def self.search_interactors
    @@counter=0
    @@interacting=Hash.new
      
    @@genes.each do |code|
      
      InteractionNetwork.get_interactors(code)
      
    end
    
  end
  
  def self.get_interactors(code,cutv=0.485)
    
      
    
      @@counter=+1
      
       
      
      res = fetch("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{code}%20AND%20species:arath/?format=tab25")
      miscore=/i\w+-\w+:(0\.\d+)/
      if res
        intact=res.body.split("\n")
        intact.each do |int|
          puts int
          
          next if int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)\(locus\sname\)/).nil?
             
            g1,g2=int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)\(locus\sname\)/)
            g1=g1[0]
            g2=g2[0]
            puts g2
          next if g1.nil?||g2.nil?
          if g1.downcase==code.downcase #get the interactor not the same gene
            
            g1=g2
            
          end
          
          score=int.match(miscore)[1].to_f
          
          next if score<cutv
          if @@genes.any?{|i| i.downcase==g1.downcase}
            @@interacting[code]=g1
            puts "INTERACTTING:#{@@interacting}"
            
          else
            puts "these were not"
            puts g1
            if @@counter<2
              
              InteractionNetwork.get_interactors(g1)
            else
              next
            end
          end
            
            
        end
      end
    
    
  end  

  

        
        
      
    
  
end