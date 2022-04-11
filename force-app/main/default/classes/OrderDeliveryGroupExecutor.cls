public with sharing class OrderDeliveryGroupExecutor implements TriggerExecutor_I {

    public static final String ORDER_STATUS_CREATED = 'Created';
    public static final String ORDER_STATUS_PENDING = 'Pending';
    public static final String ORDER_STATUS_RECEIVED = 'Received';
    public static final String ORDER_STATUS_SHIPPED = 'Shipped';
    public static final String ORDER_STATUS_CANCELED = 'Cancelled';
    public static final String ORDER_STATUS_CONFIRMED = 'Confirmed';
    public static final String ORDER_STATUS_FULFILLED = 'Fulfilled';

	public Schema.SObjectType getSObjectType() {
		return OrderDeliveryGroup.SObjectType;
	}

	public void beforeInsert(List<OrderDeliveryGroup> triggerNew) {
        for(OrderDeliveryGroup odg : triggerNew) {
            if(!String.isBlank(odg.BOLNumber__c)) {
                //create BOL object
                Bill_Of_Lading__c bol = new Bill_Of_Lading__c();
                bol.Ac_GI_Date__c = odg.Ac_GI_Date__c;
                bol.BOL_Number__c = odg.BOLNumber__c;
                bol.Delivery_Quantity__c = odg.Delivery_Quantity__c;
                bol.Material__c = odg.MaterialNumber__c;
                bol.Material_Number__c = odg.Material__c;
                bol.Account_Number_of_Vendor_or_Creditor__c = odg.Account_Number_of_Vendor_or_Creditor__c;
                bol.Vendor__c = odg.Vendor__c;

                insert bol;

                //set the lookup field to be the inserted BOL
                Bill_Of_Lading__c insertedBOL = [SELECT Id, BOL_Number__c FROM Bill_Of_Lading__c WHERE BOL_Number__c=:odg.BOLNumber__c LIMIT 1];
                odg.Bill_Of_Lading__c = insertedBOL.Id;
            }
        }
	}

	public void beforeUpdate(Map<Id, SObject> triggerOldMap, List<OrderDeliveryGroup> triggerNew) {
        for(OrderDeliveryGroup odg : triggerNew) {
            if(!String.isBlank(odg.BOLNumber__c) && odg.Bill_Of_Lading__c == null) {
                //create BOL object
                Bill_Of_Lading__c bol = new Bill_Of_Lading__c();
                bol.Ac_GI_Date__c = odg.Ac_GI_Date__c;
                bol.BOL_Number__c = odg.BOLNumber__c;
                bol.Delivery_Quantity__c = odg.Delivery_Quantity__c;
                bol.Material__c = odg.MaterialNumber__c;
                bol.Material_Number__c = odg.Material__c;
                bol.Account_Number_of_Vendor_or_Creditor__c = odg.Account_Number_of_Vendor_or_Creditor__c;
                bol.Vendor__c = odg.Vendor__c;

                insert bol;

                //set the lookup field to be the inserted BOL
                Bill_Of_Lading__c insertedBOL = [SELECT Id, BOL_Number__c FROM Bill_Of_Lading__c WHERE BOL_Number__c=:odg.BOLNumber__c LIMIT 1];
                odg.Bill_Of_Lading__c = insertedBOL.Id;
            }
            else if(odg.Bill_Of_Lading__c != null) {
                Bill_Of_Lading__c bol = [SELECT Id FROM Bill_Of_Lading__c WHERE Id=:odg.Bill_Of_Lading__c];

                bol.Ac_GI_Date__c = odg.Ac_GI_Date__c;
                bol.BOL_Number__c = odg.BOLNumber__c;
                bol.Delivery_Quantity__c = odg.Delivery_Quantity__c;
                bol.Material__c = odg.MaterialNumber__c;
                bol.Material_Number__c = odg.Material__c;
                bol.Account_Number_of_Vendor_or_Creditor__c = odg.Account_Number_of_Vendor_or_Creditor__c;
                bol.Vendor__c = odg.Vendor__c;

                update bol;
            }
        }
	}

	public void beforeDelete(List<OrderDeliveryGroup> triggerOld) {
	}

	public void afterInsert(List<OrderDeliveryGroup> triggerNew) {
	}

	public void afterUpdate(Map<Id, SObject> triggerOldMap, List<OrderDeliveryGroup> triggerNew) {
        
        //Get order Ids 
        Set<Id> orderIds = new Set<Id>();
        for (SObject odgSObj: triggerOldMap.values()) { 
            OrderDeliveryGroup odg = (OrderDeliveryGroup) odgSObj;
            orderIds.add(odg.OrderId);
        }

        // Get order delivery group for updated order id
		Map<Id, List<OrderDeliveryGroup>> orderIdToOrderDeliveryGroupMap = getOrderDeliveryGroupMap(orderIds);
		
        // Calculate rollup status for updated order group
        Map<Id, String> orderStatusMap = getOrdersRollUpStatus(orderIdToOrderDeliveryGroupMap);
        Set<Id> originalOrderIds = orderStatusMap.keySet();
        
        //Get order summary for whcih order delivery group is updated
        List<OrderSummary> orderSummariesToUpdate = new List<OrderSummary>();
        //List<OrderSummary> orderSummaries = OrderUtils.getOrderSummaryByOriginalOrderId(new List<Id>(originalOrderIds));
        List<OrderSummary> orderSummaries = OrderUtils.getOrderSummaryByOriginalOrderId(new List<Id>(orderIds));

        for (Id originalOrderId : orderStatusMap.keySet()) {
            for (OrderSummary os : orderSummaries) {
                if(os.OriginalOrderId == originalOrderId){
                    os.Status = orderStatusMap.get(originalOrderId);
                    orderSummariesToUpdate.add(os);
                    System.debug('new status for ' + os.Id + '****' + os.Status);
                }
            }
        }
        if(orderSummariesToUpdate.size() > 0){
            update orderSummariesToUpdate;
        } 

        // Calculate isHold 

        List<OrderSummary> orderSummariesHoldToUpdate = new List<OrderSummary>();
        Map<Id, Boolean> ordersHoldMap = getOrdersHoldMap(orderIdToOrderDeliveryGroupMap);
        for (Id originalOrderId : ordersHoldMap.keySet()) {

            for (OrderSummary os : orderSummaries) {
                if(os.OriginalOrderId == originalOrderId){
                    os.IsHold__c = ordersHoldMap.get(originalOrderId);
                    orderSummariesHoldToUpdate.add(os);
                    System.debug('new status for ' + os.Id + '****' + os.IsHold__c);
                }
            }
        }
        if(orderSummariesHoldToUpdate.size() > 0){
            update orderSummariesHoldToUpdate;
        }

		Map<Id, List<OrderDeliveryGroupSummary>> orderIdToOrderDeliveryGroupSummaryMap = getOrderDeliveryGroupSummaryMap(orderIds);

		List<OrderDeliveryGroupSummary> allOrderDeliveryGroupSummaries = new List<OrderDeliveryGroupSummary>();
		for (List<OrderDeliveryGroupSummary> summaries : orderIdToOrderDeliveryGroupSummaryMap.values()) {
			allOrderDeliveryGroupSummaries.addAll(summaries);
		}

		Map<Id, OrderDeliveryGroupSummary> orderDeliveryGroupSummaryMapByOrderDeliveryGroupId = OrderUtils.getOrderDeliveryGroupSummaryMapByOrderDeliveryGroupId(allOrderDeliveryGroupSummaries);

		List<OrderDeliveryGroupSummary> orderDeliveryGroupSummariesToUpdate = new List<OrderDeliveryGroupSummary>();
		for (OrderDeliveryGroup odg : triggerNew) {
			if (orderIdToOrderDeliveryGroupSummaryMap.containsKey(odg.orderId) && !orderIdToOrderDeliveryGroupSummaryMap.get(odg.orderId).isEmpty()) {
				
            
                OrderDeliveryGroupSummary associatedOrderDeliveryGroupSummary = orderDeliveryGroupSummaryMapByOrderDeliveryGroupId.get(odg.Id);

                associatedOrderDeliveryGroupSummary.AccountExternalNumber__c = odg.AccountExternalNumber__c;
                associatedOrderDeliveryGroupSummary.MaterialNumber__c = odg.MaterialNumber__c;
                associatedOrderDeliveryGroupSummary.OriginalMaterialNumber__c = odg.OriginalMaterialNumber__c;
                associatedOrderDeliveryGroupSummary.ShipmentSize__c = odg.ShipmentSize__c;
                associatedOrderDeliveryGroupSummary.ShipmentSizeType__c = odg.ShipmentSizeType__c;
                associatedOrderDeliveryGroupSummary.Quantity__c = odg.Quantity__c;
                associatedOrderDeliveryGroupSummary.ShipmentTonnage__c = odg.ShipmentTonnage__c;
                associatedOrderDeliveryGroupSummary.QuoteNumber__c = odg.QuoteNumber__c;
                associatedOrderDeliveryGroupSummary.SplitShipmentId__c = odg.SplitShipmentId__c;
                associatedOrderDeliveryGroupSummary.ShipmentStatus__c = odg.ShipmentStatus__c;
                associatedOrderDeliveryGroupSummary.Cancel_Requested_On__c = odg.Cancel_Requested_On__c;
                associatedOrderDeliveryGroupSummary.Cancel_Requested_By__c = odg.Cancel_Requested_By__c;
                associatedOrderDeliveryGroupSummary.Canceled_On__c = odg.Canceled_On__c;
                associatedOrderDeliveryGroupSummary.Canceled_By__c = odg.Canceled_By__c;
                associatedOrderDeliveryGroupSummary.Released_On__c = odg.Released_On__c;
                associatedOrderDeliveryGroupSummary.Released_By__c = odg.Released_By__c;
                associatedOrderDeliveryGroupSummary.isHold__c = odg.isHold__c;
                associatedOrderDeliveryGroupSummary.PONumber__c = odg.PONumber__c;
                associatedOrderDeliveryGroupSummary.ShipmentWeight__c = odg.ShipmentWeight__c;
                associatedOrderDeliveryGroupSummary.ShipmentDateTime__c = odg.ShipmentDateTime__c;
                associatedOrderDeliveryGroupSummary.DeliveryInstructions = odg.DeliveryInstructions;
                associatedOrderDeliveryGroupSummary.AccessCode__c = odg.AccessCode__c;
                associatedOrderDeliveryGroupSummary.BOLNumber__c = odg.BOLNumber__c;

                System.debug('----associatedOrderDeliveryGroupSummary ' + associatedOrderDeliveryGroupSummary.Id);
                orderDeliveryGroupSummariesToUpdate.add(associatedOrderDeliveryGroupSummary);
				
			}
		}

		update orderDeliveryGroupSummariesToUpdate;

	}

	public void afterDelete(List<Order> triggerOld) {
	}


	public Map<Id, List<OrderDeliveryGroup>> getOrderDeliveryGroupMap(Set<Id> orderIds) {        
		Map<Id, List<OrderDeliveryGroup>> orderIdToOrderDeliveryGroupMap = new Map<Id, List<OrderDeliveryGroup>>();
		List<OrderDeliveryGroup> relatedOrderDeliveryGroups = OrderUtils.getOrderDeliveryGroupsByOrderIds(new List<Id>(orderIds));
		for (OrderDeliveryGroup deliveryGroup : relatedOrderDeliveryGroups) {
			List<OrderDeliveryGroup> deliveryGroups = new List<OrderDeliveryGroup>();
			if (orderIdToOrderDeliveryGroupMap.containsKey(deliveryGroup.OrderId)) {
				deliveryGroups = orderIdToOrderDeliveryGroupMap.get(deliveryGroup.OrderId);
			}

			deliveryGroups.add(deliveryGroup);
			orderIdToOrderDeliveryGroupMap.put(deliveryGroup.OrderId, deliveryGroups);
		}
		return orderIdToOrderDeliveryGroupMap;
	}

    public Map<Id, List<OrderDeliveryGroupSummary>> getOrderDeliveryGroupSummaryMap(Set<Id> orderIds) {
		Map<Id, List<OrderDeliveryGroupSummary>> orderIdToOrderDeliveryGroupSummaryMap = new Map<Id, List<OrderDeliveryGroupSummary>>();
		List<OrderDeliveryGroupSummary> relatedOrderDeliveryGroupSummaries = OrderUtils.getOrderDeliveryGroupSummariesByOrderIds(new List<Id>(orderIds));
		for (OrderDeliveryGroupSummary deliveryGroup : relatedOrderDeliveryGroupSummaries) {
			List<OrderDeliveryGroupSummary> deliveryGroups = new List<OrderDeliveryGroupSummary>();
			if (orderIdToOrderDeliveryGroupSummaryMap.containsKey(deliveryGroup.OriginalOrderDeliveryGroup.OrderId)) {
				deliveryGroups = orderIdToOrderDeliveryGroupSummaryMap.get(deliveryGroup.OriginalOrderDeliveryGroup.OrderId);
			}

			deliveryGroups.add(deliveryGroup);
			orderIdToOrderDeliveryGroupSummaryMap.put(deliveryGroup.OriginalOrderDeliveryGroup.OrderId, deliveryGroups);
		}

		return orderIdToOrderDeliveryGroupSummaryMap;
	}


    private Map<Id, String> getOrdersRollUpStatus(Map<Id, List<OrderDeliveryGroup>> orderIdToOrderDeliveryGroupMap){
        String rollUpStatus = '';
        Integer noOfOrderCreated = 0;
        Integer noOfOrderCanceled = 0;
        Integer noOfOrderShipped = 0;
        Integer noOfOrderReceived = 0;        

        Map<Id, String> orderStatusMap = new Map<Id, String>();
        for(String key:orderIdToOrderDeliveryGroupMap.keySet()){ 

            noOfOrderCreated = 0;
            noOfOrderCanceled = 0;
            noOfOrderShipped = 0;
            noOfOrderReceived = 0;
            List<OrderDeliveryGroup> orderDeliveryGroups = orderIdToOrderDeliveryGroupMap.get(key);

            for (OrderDeliveryGroup odg : orderDeliveryGroups) {                
                if(String.isNotBlank(odg.ShipmentStatus__c)){
                    if(odg.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_CANCELED)){
                        noOfOrderCanceled += 1;
                    }
                    else if(odg.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_CREATED)){
                        noOfOrderCreated += 1;
                    }
                    else if(odg.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_SHIPPED)){
                        noOfOrderShipped += 1;
                    }
                    else if(odg.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_RECEIVED)){
                        noOfOrderReceived += 1;
                    }
                }
            }

            if(noOfOrderCanceled == orderDeliveryGroups.size()){
                rollUpStatus = ORDER_STATUS_CANCELED;
            } else if(noOfOrderCreated == orderDeliveryGroups.size()){
                rollUpStatus = ORDER_STATUS_CREATED;
            } else if(noOfOrderShipped == orderDeliveryGroups.size()){
                rollUpStatus = ORDER_STATUS_SHIPPED;
            } else if(noOfOrderReceived == orderDeliveryGroups.size()){
                rollUpStatus = ORDER_STATUS_RECEIVED;
            }             

            if(!rollUpStatus.equalsIgnoreCase(ORDER_STATUS_RECEIVED) && !rollUpStatus.equalsIgnoreCase(ORDER_STATUS_SHIPPED)){
                if(noOfOrderReceived > 0){
                    rollUpStatus = ORDER_STATUS_RECEIVED;
                }
                 
                if((!rollUpStatus.equalsIgnoreCase(ORDER_STATUS_RECEIVED) && noOfOrderShipped > 0)){
                    rollUpStatus = ORDER_STATUS_SHIPPED;
                }
            }

            if(String.isNotBlank(rollUpStatus)){
                orderStatusMap.put(key, rollUpStatus);
            }
        }
        return orderStatusMap;
    }

    private Map<Id, Boolean> getOrdersHoldMap(Map<Id, List<OrderDeliveryGroup>> orderIdToOrderDeliveryGroupMap){
        Boolean isHold = false;        

        Map<Id, Boolean> ordersHoldMap = new Map<Id, Boolean>();
        for(String key:orderIdToOrderDeliveryGroupMap.keySet()){ 

            isHold = false;    
            List<OrderDeliveryGroup> orderDeliveryGroups = orderIdToOrderDeliveryGroupMap.get(key);
 
            for (OrderDeliveryGroup odg : orderDeliveryGroups) {                
                if(odg.IsHold__c == true){
                    isHold = true;
                    break;    
                }
            }
            ordersHoldMap.put(key, isHold);
        }
        System.debug('ordersHoldMap size' + ordersHoldMap.size() + ' ' + isHold);
        return ordersHoldMap;
    }
}