require 'rest-client'
require 'json'
class InteractionNetwork
  
  @@num = 0 #to count the number of networks
  attr_accessor :network #assign a number to each network
  attr_accessor :members #list with the members of the network
  attr_accessor :kegg_path #KEGG annotations of the members
  attr_accessor :go_terms #GO biological proccesses annotations of the members
  @@all_interactions=[] #list with all the objects of the class
  @@genes=[] #list with all the genes read from the file
  
  def initialize(params={})
    @network = params.fetch(:network,0)
    @type = params.fetch(:type,'undefined')
    @members = params.fetch(:members,'NA')
    @kegg_path = annotate_kegg(ids=@members) #get KEGG pathways annotation of all the members in a network
    @go_terms = annotate_GO(ids=@members) #get GO biological processes annotation of all the members in a network
    @@num += 1 #every time a network object is initialized count it
    @@all_interactions << self #add all the objects to this list
  end
  
  def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="")
    #class method to retrieve web data avoiding possible crashes
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
   
  def self.get_agi(file) #class method to retrieve gene codes from a file and add them to class variable
    File.open(file).each do |code|
      @@genes << code.strip.downcase
    end
    
  end
  
  def self.num #class method to get the number of networks
    return @@num
  end
  
  def self.search_interactors(cutv=0.485) #class method to search the interactions of the genes from the previous file
    #and save them in a class variable if MIscore is bigger than the cutoff value (cutv)
    @@interacting=Hash.new
    @@genes.each do |code|
      res = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{code}/?format=tab25")
      #get the interactors of each AGI locus from BAR UToronto using psicquic webservice
      miscore=/i\w+-\w+:(0\.\d+)/ #regular expression to match the score of the interaction
      if res
        intact=res.body.split("\n") #tab25 is a format in which each interaction is separated by newline, get list of interactions
        intact.each do |int| #for one interaction..
          next if int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/).nil? #skip if there are not any AGI locus
          g1,g2=int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/) #save the locus of the two interactors
          next if g1.nil?||g2.nil? #skip if it didn't find a locus for one interactor
          g1=g1[0] #scan returns a list, get the element
          g2=g2[0]
          if g1.downcase==code.downcase and g2.downcase != code.downcase #get the interactor not the gene we used to search
            g1=g2
          end
          
          score=int.match(miscore)[1].to_f #get the score of the interaction and transform it to float (from string)
          next if score<cutv #skip if the score is less than the cutoff value set
          next if g1.downcase == code.downcase #skip if the interactor is same locus as the one used to search
          if @@genes.include?(g1.downcase) #if the interactor is on the list of genes
             @@interacting[code]=g1 #save it in this hash
          else #if the interactor is not on the list of genes
            g0=g1 #save this interactor in a different variable and search for it's interactors
            res = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{g0}/?format=tab25")
            if res
              intact2=res.body.split("\n") #explained above
              intact2.each do |int2|
                next if int2.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/).nil?
                g1,g2=int2.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/)
                next if g1.nil?||g2.nil? #same as before
                g1=g1[0]
                g2=g2[0]
                if g1.downcase==g0.downcase #get the interactor not the gene used to search
                  g1=g2
                end
                next if g1.downcase==code.downcase #avoid infinite loops
                score=int.match(miscore)[1].to_f
            
                next if score<cutv
                if @@genes.include?(g1.downcase)
                  if !@@interacting.keys.include?(code) #(does not include) if no other interactions have been found for this locus before
                    # to avoid over-writing interactions
                      @@interacting[code]=[g0,g1] #save the first locus used to search, the intermediary gene (g0) and another locus
                      #found on the list
                  end
                end
              end
            end
          end  
        end
      end
    end
  end
  
  def annotate_kegg(ids,db="genes",field="pathways") #method to annotate every member of a network with KEGG
    annotations=[] #list for annotations
    ids.each do |id| #the members are saved in a list
      resp = InteractionNetwork.fetch("http://togows.org/entry/#{db}/ath:#{id}/#{field}.json")
      #using TOGO "REST" API with genes database and pathways field
      if resp
        res=JSON.parse(resp.body)[0] #access the results (json format is a list)
        res.each do |kegg_id,kegg_p| #data is in hash format, get
            annotations << [kegg_id,kegg_p] #save the annotations of each locus in the list
        end
      end
      
      return annotations #return the list of annotations for the network
    end  
  end    
  
  def annotate_GO(ids,db="uniprot",field="dr") #annotate with GO from uniprot cross refferences
    annotations=[]
    ids.each do |id|
      resp = InteractionNetwork.fetch("http://togows.org/entry/#{db}/#{id}/#{field}.json")
      
      if resp
        res=JSON.parse(resp.body)[0]
        res["GO"].each do |term| #dr format is hashes --> list of lists
          #GO lists have three elements: GO-id,GOterm(class:definition)
          if term[1]=~/P:/ #P=biological processes class
            goid=term[0]
            goterm=term[1].match(/:(.+)/)[1]
            annotations << [goid,goterm]
          end
        end
        return annotations.uniq # some GO terms are repeated in this database
      end
    end      
  end
  
  def self.load #create the objects of this class
    count=0 #for the number of network
    @@interacting.each do |key,value| #interacting class variable is a hash
      ids=[]
      count+=1
      if value.is_a?(Array) && value.count == 2 && key.is_a?(String)
        value.each do |v|
          ids << v  
        end
        ids << key
        InteractionNetwork.new(:network => count, :members =>ids)
      elsif value.is_a?(String) && key.is_a?(String)
        ids=[key,value]
        InteractionNetwork.new(:network => count, :members =>ids)
      end
    end
  end
  
  def self.get_all # get the list with all the objects
    return @@all_interactions
  end
end