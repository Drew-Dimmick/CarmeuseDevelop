public with sharing class AccountTriggerExecutor implements TriggerExecutor_I {

	public Schema.SObjectType getSObjectType() {
		return Account.SObjectType;
	}

	public void beforeInsert(List<Account> triggerNew) {

	}

	public void beforeUpdate(Map<Id, SObject> triggerOldMap, List<Account> triggerNew) {
	}

	public void beforeDelete(List<Account> triggerOld) {
	}

	public void afterInsert(List<Account> triggerNew) {
        List<Account> accList = new List<Account>();
        
        for(Account acc : triggerNew) {
            accList.add(acc);
        }

        if(accList.size() > 0) {
            Database.executebatch(new AccountTriggerBatch(accList), 70);
        }
	}

	public void afterUpdate(Map<Id, SObject> triggerOldMap, List<Account> triggerNew) {
		
	}

	public void afterDelete(List<Account> triggerOld) {

	}
}
