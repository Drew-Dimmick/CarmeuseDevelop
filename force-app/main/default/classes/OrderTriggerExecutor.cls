public with sharing class OrderTriggerExecutor implements TriggerExecutor_I {

	public Schema.SObjectType getSObjectType() {
		return Order.SObjectType;
	}

	public void beforeInsert(List<Order> triggerNew) {
	}

	public void beforeUpdate(Map<Id, SObject> triggerOldMap, List<Order> triggerNew) {
	}

	public void beforeDelete(List<Order> triggerOld) {
	}

	public void afterInsert(List<Order> triggerNew) {
	}

	public void afterUpdate(Map<Id, SObject> triggerOldMap, List<Order> triggerNew) {
		Map<Id, List<OrderDeliveryGroup>> orderIdToOrderDeliveryGroupMap = getOrderDeliveryGroupMap(triggerOldMap.keySet());
		Map<Id, List<OrderDeliveryGroupSummary>> orderIdToOrderDeliveryGroupSummaryMap = getOrderDeliveryGroupSummaryMap(triggerOldMap.keySet());

		List<OrderDeliveryGroupSummary> allOrderDeliveryGroupSummaries = new List<OrderDeliveryGroupSummary>();
		for (List<OrderDeliveryGroupSummary> summaries : orderIdToOrderDeliveryGroupSummaryMap.values()) {
			allOrderDeliveryGroupSummaries.addAll(summaries);
		}

		Map<Id, OrderDeliveryGroupSummary> orderDeliveryGroupSummaryMapByOrderDeliveryGroupId = OrderUtils.getOrderDeliveryGroupSummaryMapByOrderDeliveryGroupId(allOrderDeliveryGroupSummaries);

		List<OrderDeliveryGroupSummary> orderDeliveryGroupSummariesToUpdate = new List<OrderDeliveryGroupSummary>();
		for (Order order : triggerNew) {
			if (orderIdToOrderDeliveryGroupSummaryMap.containsKey(order.Id) && !orderIdToOrderDeliveryGroupSummaryMap.get(order.Id).isEmpty()) {
				List<OrderDeliveryGroup> orderDeliveryGroups = orderIdToOrderDeliveryGroupMap.get(order.Id);

				for (OrderDeliveryGroup odg : orderDeliveryGroups) {
					OrderDeliveryGroupSummary associatedOrderDeliveryGroupSummary = orderDeliveryGroupSummaryMapByOrderDeliveryGroupId.get(odg.Id);

					associatedOrderDeliveryGroupSummary.AccountExternalNumber__c = odg.AccountExternalNumber__c;
					associatedOrderDeliveryGroupSummary.MaterialNumber__c = odg.MaterialNumber__c;
					associatedOrderDeliveryGroupSummary.ShipmentSize__c = odg.ShipmentSize__c;
					associatedOrderDeliveryGroupSummary.ShipmentSizeType__c = odg.ShipmentSizeType__c;
					associatedOrderDeliveryGroupSummary.Quantity__c = odg.Quantity__c;
					associatedOrderDeliveryGroupSummary.ShipmentTonnage__c = odg.ShipmentTonnage__c;
					associatedOrderDeliveryGroupSummary.QuoteNumber__c = odg.QuoteNumber__c;
					associatedOrderDeliveryGroupSummary.SplitShipmentId__c = odg.SplitShipmentId__c;
					associatedOrderDeliveryGroupSummary.ShipmentStatus__c = odg.ShipmentStatus__c;
					associatedOrderDeliveryGroupSummary.PONumber__c = odg.PONumber__c;
					associatedOrderDeliveryGroupSummary.IsHold__c = odg.IsHold__c;
					associatedOrderDeliveryGroupSummary.ShipmentWeight__c = odg.ShipmentWeight__c;
					associatedOrderDeliveryGroupSummary.ShipmentDateTime__c = odg.ShipmentDateTime__c;
					associatedOrderDeliveryGroupSummary.BOLNumber__c = odg.BOLNumber__c;

					if(odg.DesiredDeliveryDate != null){
						associatedOrderDeliveryGroupSummary.DesiredDeliveryDate = Datetime.newInstance(odg.DesiredDeliveryDate.year(), odg.DesiredDeliveryDate.month(), odg.DesiredDeliveryDate.day(), 12, 0, 0);
					}
					
					associatedOrderDeliveryGroupSummary.DeliveryDate__c = odg.DesiredDeliveryDate;
					// deliveryGroup.DesiredDeliveryDate = DateTime.newInstance(deliveryDate.year(), deliveryDate.month(), deliveryDate.day());

					associatedOrderDeliveryGroupSummary.DeliverToStreet = odg.DeliverToStreet;
					associatedOrderDeliveryGroupSummary.DeliverToCity = odg.DeliverToCity;
					associatedOrderDeliveryGroupSummary.DeliverToState = odg.DeliverToState;
					associatedOrderDeliveryGroupSummary.DeliverToPostalCode = odg.DeliverToPostalCode;
					associatedOrderDeliveryGroupSummary.DeliverToCountry = odg.DeliverToCountry;

					orderDeliveryGroupSummariesToUpdate.add(associatedOrderDeliveryGroupSummary);
				}
			}
		}

		System.debug('---- Order delivery group summaries to update ----');
		System.debug(orderDeliveryGroupSummariesToUpdate);
		update orderDeliveryGroupSummariesToUpdate;

		//Call future method to create order summary for SAP external activated orders
		ThirdPartyOrderManagement.processOrderRecords(triggerOldMap.keySet());
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
}