public with sharing class CartTriggerExecutor implements TriggerExecutor_I {

	public Schema.SObjectType getSObjectType() {
		return WebCart.SObjectType;
	}

	public void beforeInsert(List<WebCart> triggerNew) {
	}

	public void beforeUpdate(Map<Id, SObject> triggerOldMap, List<WebCart> triggerNew) {
	}

	public void beforeDelete(List<WebCart> triggerOld) {
	}

	public void afterInsert(List<WebCart> triggerNew) {
	}

	public void afterUpdate(Map<Id, SObject> triggerOldMap, List<WebCart> triggerNew) {
		System.debug('---- Cart trigger after update ----');

		Map<Id, List<CartDeliveryGroup>> cartIdToCartDeliveryGroupMap = getCartDeliveryGroupMap(triggerOldMap.keySet());
		Map<Id, List<OrderDeliveryGroup>> cartIdToOrderDeliveryGroupMap = getOrderDeliveryGroupMap(triggerOldMap.keySet());

		Set<Id> cpaIds = new Set<Id>();
		for (List<CartDeliveryGroup> groups : cartIdToCartDeliveryGroupMap.values()) {
			for (CartDeliveryGroup cdg : groups) {
				cpaIds.add((Id) cdg.BillingAddress__c);
				cpaIds.add((Id) cdg.ShippingAddress__c);
			}
		}

		Map<Id, ContactPointAddress> relevantAddresses = new Map<Id, ContactPointAddress>([
			SELECT Id, Address, City, State, Street, PostalCode, Country
			FROM ContactPointAddress
			WHERE Id IN :cpaIds
		]);

		System.debug('---- Cart delivery group map ----');
		System.debug(cartIdToCartDeliveryGroupMap);
		System.debug('---- Order delivery group map ----');
		System.debug(cartIdToOrderDeliveryGroupMap);
		List<OrderDeliveryGroup> orderDeliveryGroupsToUpdate = new List<OrderDeliveryGroup>();

		Map<Id, ContactPointAddress> orderIdToContactPointBillingAddress = new Map<Id, ContactPointAddress>();

		for (WebCart cart : triggerNew) {
			System.debug('---- For cart: ----');
			System.debug('old:');
			System.debug(triggerOldMap.get(cart.Id));
			System.debug('new:');
			System.debug(cart);

			if (!cartIdToOrderDeliveryGroupMap.isEmpty()) {
				List<CartDeliveryGroup> cartDeliveryGroups = cartIdToCartDeliveryGroupMap.get(cart.Id);
				List<OrderDeliveryGroup> orderDeliveryGroups = cartIdToOrderDeliveryGroupMap.get(cart.Id);

				Set<Id> processedOrderDeliveryGroupIds = new Set<Id>();
				for (CartDeliveryGroup cdg : cartDeliveryGroups) {
					OrderDeliveryGroup associatedOrderDeliveryGroup;

					System.debug('---- For cart delivery group: ----');
					System.debug(cdg);

					for (OrderDeliveryGroup odg : orderDeliveryGroups) {
						if (!processedOrderDeliveryGroupIds.contains(odg.Id) &&
								odg.DesiredDeliveryDate == cdg.DesiredDeliveryDate) {
							associatedOrderDeliveryGroup = odg;
							processedOrderDeliveryGroupIds.add(odg.Id);
							break;
						}
					}

					System.debug('---- Associated order delivery group: ----');
					System.debug(associatedOrderDeliveryGroup);

					System.debug('---- Processed delivery group set: ----');
					System.debug(processedOrderDeliveryGroupIds);

					ContactPointAddress billingAddress = relevantAddresses.get(cdg.BillingAddress__c);
					ContactPointAddress shippingAddress = relevantAddresses.get(cdg.ShippingAddress__c);

					System.debug('----- ContactPointAddresses --------');
					System.debug(billingAddress);
					System.debug(shippingAddress);

					associatedOrderDeliveryGroup.AccountExternalNumber__c = cdg.AccountExternalNumber__c;
					associatedOrderDeliveryGroup.MaterialNumber__c = cdg.MaterialNumber__c;
					associatedOrderDeliveryGroup.ShipmentSize__c = cdg.Shipment_Size__c;
					associatedOrderDeliveryGroup.ShipmentSizeType__c = cdg.ShipmentSizeType__c;
					associatedOrderDeliveryGroup.Quantity__c = cdg.Quantity__c;
					associatedOrderDeliveryGroup.ShipmentTonnage__c = cdg.ShipmentTonnage__c;
					associatedOrderDeliveryGroup.QuoteNumber__c = cdg.Quote_Number__c;
					associatedOrderDeliveryGroup.DeliveryInstructions = cdg.DeliveryText__c;
					associatedOrderDeliveryGroup.SplitShipmentId__c = cdg.SplitShipmentId__c;
					associatedOrderDeliveryGroup.PONumber__c = cdg.PONumber__c;
					associatedOrderDeliveryGroup.IsHold__c = cdg.IsHold__c;

					associatedOrderDeliveryGroup.DeliverToStreet = shippingAddress.Street;
					associatedOrderDeliveryGroup.DeliverToCity = shippingAddress.City;
					associatedOrderDeliveryGroup.DeliverToState = shippingAddress.State;
					associatedOrderDeliveryGroup.DeliverToPostalCode = shippingAddress.PostalCode;
					associatedOrderDeliveryGroup.DeliverToCountry = shippingAddress.Country;
					// associatedOrderDeliveryGroup.DeliverToLatitude = shippingAddress.Latitude;
					// associatedOrderDeliveryGroup.DeliverToLongitude = shippingAddress.Longitude;

					orderIdToContactPointBillingAddress.put(associatedOrderDeliveryGroup.OrderId, billingAddress);

					orderDeliveryGroupsToUpdate.add(associatedOrderDeliveryGroup);
				}
			}
		}

		List<Order> ordersToUpdate = [
			SELECT Id
			FROM Order
			WHERE Id IN :orderIdToContactPointBillingAddress.keySet()
		];

		for(Order orderToUpdate : ordersToUpdate) {
			ContactPointAddress billingAddress = orderIdToContactPointBillingAddress.get(orderToUpdate.Id);
			if(billingAddress != null) {
				orderToUpdate.BillingCity = billingAddress.City;
				orderToUpdate.BillingState = billingAddress.State;
				orderToUpdate.BillingStreet = billingAddress.Street;
				orderToUpdate.BillingCountry = billingAddress.Country;
				orderToUpdate.BillingPostalCode = billingAddress.PostalCode;
			}
		}

		System.debug('------ Orders to update ------ ');
		System.debug(ordersToUpdate);
		// update ordersToUpdate;

		System.debug('----- Order delivery groups to update -------');
		System.debug(orderDeliveryGroupsToUpdate);

		update orderDeliveryGroupsToUpdate;
	}

	public void afterDelete(List<WebCart> triggerOld) {
	}

	public Map<Id, List<CartDeliveryGroup>> getCartDeliveryGroupMap(Set<Id> cartIds) {
		Map<Id, List<CartDeliveryGroup>> cartIdToCartDeliveryGroupMap = new Map<Id, List<CartDeliveryGroup>>();
		List<CartDeliveryGroup> relatedCartDeliveryGroups = OrderUtils.getCartDeliveryGroupsByCartIds(new List<Id>(cartIds));
		for (CartDeliveryGroup deliveryGroup : relatedCartDeliveryGroups) {
			List<CartDeliveryGroup> deliveryGroups = new List<CartDeliveryGroup>();

			if (cartIdToCartDeliveryGroupMap.containsKey(deliveryGroup.CartId)) {
				deliveryGroups = cartIdToCartDeliveryGroupMap.get(deliveryGroup.CartId);
			}

			deliveryGroups.add(deliveryGroup);
			cartIdToCartDeliveryGroupMap.put(deliveryGroup.CartId, deliveryGroups);
		}

		return cartIdToCartDeliveryGroupMap;
	}

	public Map<Id, List<OrderDeliveryGroup>> getOrderDeliveryGroupMap(Set<Id> cartIds) {
		Map<Id, Id> orderIdToCartIdMap = OrderUtils.getOrderIdToCartIdMap(new List<Id>(cartIds));

		Map<Id, List<OrderDeliveryGroup>> cartIdToOrderDeliveryGroupMap = new Map<Id, List<OrderDeliveryGroup>>();
		List<OrderDeliveryGroup> relatedOrderDeliveryGroups = OrderUtils.getRelatedOrderDeliveryGroupsByCartIds(new List<Id>(cartIds));
		for (OrderDeliveryGroup deliveryGroup : relatedOrderDeliveryGroups) {
			Id cartId = orderIdToCartIdMap.get(deliveryGroup.OrderId);

			List<OrderDeliveryGroup> deliveryGroups = new List<OrderDeliveryGroup>();
			if (cartIdToOrderDeliveryGroupMap.containsKey(cartId)) {
				deliveryGroups = cartIdToOrderDeliveryGroupMap.get(cartId);
			}

			deliveryGroups.add(deliveryGroup);
			cartIdToOrderDeliveryGroupMap.put(cartId, deliveryGroups);
		}

		return cartIdToOrderDeliveryGroupMap;
	}

	// This method is in the order trigger.
	/*
	public Map<Id, List<OrderDeliveryGroupSummary>> getOrderDeliveryGroupSummaryMap(Set<Id> cartIds) {
		Map<Id, Id> orderIdToCartIdMap = OrderUtils.getOrderIdToCartIdMap(new List<Id>(cartIds));

		Map<Id, List<OrderDeliveryGroupSummary>> cartIdToOrderDeliveryGroupSummaryMap = new Map<Id, List<OrderDeliveryGroupSummary>>();
		List<OrderDeliveryGroupSummary> relatedOrderDeliveryGroupSummaries = OrderUtils.getRelatedOrderDeliveryGroupSummariesByCartIds(new List<Id>(cartIds));
		for (OrderDeliveryGroupSummary deliveryGroup : relatedOrderDeliveryGroupSummaries) {
			Id cartId = orderIdToCartIdMap.get(deliveryGroup.OriginalOrderDeliveryGroup.OrderId);

			List<OrderDeliveryGroupSummary> deliveryGroups = new List<OrderDeliveryGroupSummary>();
			if (cartIdToOrderDeliveryGroupSummaryMap.containsKey(cartId)) {
				deliveryGroups = cartIdToOrderDeliveryGroupSummaryMap.get(cartId);
			}

			deliveryGroups.add(deliveryGroup);
			cartIdToOrderDeliveryGroupSummaryMap.put(cartId, deliveryGroups);
		}

		return cartIdToOrderDeliveryGroupSummaryMap;
	}
	*/
}