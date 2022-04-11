public with sharing class ProductTriggerExecutor implements TriggerExecutor_I {

	public Schema.SObjectType getSObjectType() {
		return Product2.SObjectType;
	}

	public void beforeInsert(List<Product2> triggerNew) {
	}

	public void beforeUpdate(Map<Id, SObject> triggerOldMap, List<Product2> triggerNew) {
	}

	public void beforeDelete(List<Product2> triggerOld) {
	}

	public void afterInsert(List<Product2> triggerNew) {
		List<Product2> productList = new List<Product2>();
        
        for(Product2 product : triggerNew) {
            productList.add(product);
        }

        if(productList.size() > 0) {
            Database.executebatch(new ProductTriggerBatch(productList));
        }
	}

	public void afterUpdate(Map<Id, SObject> triggerOldMap, List<Product2> triggerNew) {
		
	}

	public void afterDelete(List<Product2> triggerOld) {

	}
}
