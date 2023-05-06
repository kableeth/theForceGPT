({
  registerUtilityClickHandler: function(component, event, helper){
        var utilityBarAPI = component.find("utilitybar");
	  var eventHandler = function(response){
            console.log(response);
        };
        
        utilityBarAPI.onUtilityClick({ 
               eventHandler: eventHandler 
        }).then(function(result){
            console.log(result);
        }).catch(function(error){
        	console.log(error);
        });
    }
})