// chatContainerCmpController.js
({
    doInit: function (component, event, helper) {
        var utilityAPI = component.find('utilitybar');
        
        utilityAPI.getAllUtilityInfo().then(function (response) {
            if (typeof response !== 'undefined') {
                component.set('v.hasUtilityBar', true);
                
                // log the utility ids
                for (var i = 0; i < response.length; i++) {
                    console.log(response[i].id);
                }
                
            } else {
                component.set('v.hasUtilityBar', false);
            }
        });
    },
})
