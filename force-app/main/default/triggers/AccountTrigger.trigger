trigger AccountTrigger on Account (before insert, before delete, before update, after update, after insert) {
    
    if(Trigger.isBefore && Trigger.isInsert){
        AccountTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isInsert){
        system.debug('Invoking Create members methods');
        AccountTriggerHandler.createTeamMembers(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        system.debug('Invoking Create members methods');
        AccountTriggerHandler.validateTeamMembers(Trigger.new, Trigger.oldMap);
        AccountTriggerHandler.handleActivation(Trigger.new, Trigger.oldMap);
    }
}