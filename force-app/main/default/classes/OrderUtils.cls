public without sharing class OrderUtils {
	public static Id getOrderIdByCartId(Id cartId) {
		return [
				SELECT OrderId
				FROM CartCheckoutSession
				WHERE WebCartId = :cartId
				AND IsArchived = false
		].OrderId;
	}

	public static List<Id> getOrderIdsByCartIds(List<Id> cartIds) {
		List<CartCheckoutSession> sessions = [
				SELECT OrderId
				FROM CartCheckoutSession
				WHERE WebCartId IN :cartIds
				AND IsArchived = false
		];

		List<Id> orderIds = new List<Id>();
		for (CartCheckoutSession session : sessions) {
			orderIds.add(session.OrderId);
		}

		return orderIds;
	}

	public static Map<Id, OrderDeliveryGroupSummary> getOrderDeliveryGroupSummaryMapByOrderDeliveryGroupId(List<OrderDeliveryGroupSummary> odgs) {
		Map<Id, OrderDeliveryGroupSummary> orderDeliveryGroupSummaryMapByOrderDeliveryGroupId = new Map<Id, OrderDeliveryGroupSummary>();

		for (OrderDeliveryGroupSummary ogds : odgs) {
			orderDeliveryGroupSummaryMapByOrderDeliveryGroupId.put(ogds.OriginalOrderDeliveryGroupId, ogds);
		}

		return orderDeliveryGroupSummaryMapByOrderDeliveryGroupId;
	}

	public static Map<Id, Id> getOrderIdToCartIdMap(List<Id> cartIds) {
		List<CartCheckoutSession> sessions = [
				SELECT OrderId, WebCartId
				FROM CartCheckoutSession
				WHERE WebCartId IN :cartIds
				AND IsArchived = false
		];

		Map<Id, Id> orderIdsToCartIds = new Map<Id, Id>();
		for (CartCheckoutSession session : sessions) {
			orderIdsToCartIds.put(session.OrderId, session.WebCartId);
		}

		return orderIdsToCartIds;
	}

	public static List<OrderDeliveryGroup> getRelatedOrderDeliveryGroupsByCartId(Id cartId) {
		Id orderId = getOrderIdByCartId(cartId);

		return [
				SELECT FIELDS(STANDARD)
				FROM OrderDeliveryGroup
				WHERE OrderId = :orderId
		];
	}

	public static List<OrderDeliveryGroup> getRelatedOrderDeliveryGroupsByCartIds(List<Id> cartIds) {
		List<Id> orderIds = getOrderIdsByCartIds(cartIds);

		return [
				SELECT FIELDS(STANDARD)
				FROM OrderDeliveryGroup
				WHERE OrderId IN :orderIds
		];
	}

	public static List<OrderDeliveryGroupSummary> getRelatedOrderDeliveryGroupSummariesByCartId(Id cartId) {
		Id orderId = getOrderIdByCartId(cartId);

		return [
				SELECT FIELDS(STANDARD), OriginalOrderDeliveryGroup.OrderId
				FROM OrderDeliveryGroupSummary
				WHERE OrderSummary.OriginalOrderId = :orderId
		];
	}

	public static List<OrderDeliveryGroupSummary> getOrderDeliveryGroupSummariesByOrderIds(List<Id> orderIds) {
		return [
				SELECT FIELDS(STANDARD), OriginalOrderDeliveryGroup.OrderId
				FROM OrderDeliveryGroupSummary
				WHERE OrderSummary.OriginalOrderId IN :orderIds
		];
	}

	public static List<OrderDeliveryGroup> getOrderDeliveryGroupsByOrderIds(List<Id> orderIds) {
		return [
				SELECT FIELDS(STANDARD), AccountExternalNumber__c, MaterialNumber__c, ShipmentSize__c, ShipmentStatus__c,
				ShipmentSizeType__c, Quantity__c, ShipmentTonnage__c, QuoteNumber__c, SplitShipmentId__c, PONumber__c,
						IsHold__c, OriginalMaterialNumber__c, AccessCode__c,ShipmentWeight__c,ShipmentDateTime__c,BOLNumber__c
				FROM OrderDeliveryGroup
				WHERE OrderId IN :orderIds
		];
	}

	public static List<OrderDeliveryGroupSummary> getRelatedOrderDeliveryGroupSummariesByCartIds(List<Id> cartIds) {
		List<Id> orderIds = getOrderIdsByCartIds(cartIds);

		return [
				SELECT FIELDS(STANDARD), OriginalOrderDeliveryGroup.OrderId
				FROM OrderDeliveryGroupSummary
				WHERE OrderSummary.OriginalOrderId IN :orderIds
		];
	}

	public static List<CartDeliveryGroup> getCartDeliveryGroupsByCartId(Id cartId) {
		return [
				SELECT FIELDS(STANDARD), MaterialNumber__c, AccountExternalNumber__c,
						ShipmentSizeType__c, Shipment_Size__c, ShipmentTonnage__c,
						Quantity__c, Quote_Number__c, SplitShipmentId__c, PONumber__c,
						IsHold__c, DeliveryText__c, BillingAddress__c, ShippingAddress__c
				FROM CartDeliveryGroup
				WHERE CartId = :cartId
				LIMIT 1
		];
	}

	public static List<CartDeliveryGroup> getCartDeliveryGroupsByCartIds(List<Id> cartIds) {
		return [
				SELECT FIELDS(STANDARD), MaterialNumber__c, AccountExternalNumber__c,
						ShipmentSizeType__c, Shipment_Size__c, ShipmentTonnage__c, 
						Quantity__c, Quote_Number__c, SplitShipmentId__c, PONumber__c,
						IsHold__c, DeliveryText__c, BillingAddress__c, ShippingAddress__c
				FROM CartDeliveryGroup
				WHERE CartId IN :cartIds
		];
	}

	public static List<CartItem> getCartItemsByCartId(Id cartId) {
		return [
				SELECT FIELDS(STANDARD)
				FROM CartItem
				WHERE CartId = :cartId
		];
	}

	public static List<Product2> getProductsByIds(List<Id> productIds) {
		return [
				SELECT FIELDS(STANDARD), MaterialNumber__c, Shipping_Condition__c
				FROM Product2
				WHERE Id IN :productIds
		];
	}

	// public static List<PricebookEntry> getPricebookEntriesByProductIdsAndAccount(List<Id> productIds, Account acc) {
	// 	System.debug ('devang productIds = ' + productIds);
	// 	System.debug ('devang acc name = ' + acc);
	// 	return [
	// 			SELECT FIELDS(STANDARD), Quote_Number__c
	// 			FROM PricebookEntry
	// 			WHERE Product2Id IN :productIds
	// 			AND Pricebook2.Name LIKE :'%' + acc.Name + '%'
	// 			AND IsActive = TRUE
	// 	];
	// }

	public static List<PricebookEntry> getPricebookEntriesByProductIdsAndAccount(set<Id> productIds, set<Id> pricebookIds) {
		
		
		return [
				SELECT FIELDS(STANDARD), Quote_Number__c, ValidFrom__c, ValidTo__c
				FROM PricebookEntry
				WHERE Product2Id IN :productIds
				AND Pricebook2Id IN :pricebookIds
				AND IsActive = TRUE
		];
	}


	public static set<Id> getPricebookIds(Id  accountId) {
	
		// BuyerGroup Member - BuyerGroup Id
		//
		//Id buyerGroupId = '0ZI3O0000004DAHWA2';
		set<Id> buyerGroupIds = new set<Id>();
	
		for(BuyerGroupMember rec :  [SELECT BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = :accountId] ){
			buyerGroupIds.add(rec.BuyerGroupId);
		}

		List <BuyerGroupPricebook>  buyerPriceBooks = [SELECT Pricebook2Id FROM BuyerGroupPricebook WHERE BuyerGroupId IN :buyerGroupIds AND IsActive = TRUE];

		set<Id> pricebookIds  = new set<Id>();
		for(BuyerGroupPricebook rec :  buyerPriceBooks ){
			pricebookIds.add(rec.Pricebook2Id);
		}
				
		return pricebookIds;
	}

	// move into different class
	public static Contact getLoggedInCommunityUserContact() {


		Id contactId = [
				SELECT Id, ContactId
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		].ContactId;

		return [
				SELECT FIELDS(STANDARD), Account.AccountExternalNumber__c, Account.IsHold__c,
					Account.Default_Delivery_Text__c, Account.Default_Load_Volume__c, 
					Account.DefaultPONumber__c, Account.Default_Shipment_Type__c, Account.Name
				FROM Contact
				WHERE Id = :contactId
		];

	}

	public static Account getEffectiveAccount(Id cartId) {


		Id accountId = [
				SELECT AccountId
				FROM WebCart
				WHERE Id = :cartId
				LIMIT 1
		].AccountId;

		return [
				SELECT Id, AccountExternalNumber__c,IsHold__c,
					Default_Delivery_Text__c, Default_Load_Volume__c, 
					DefaultPONumber__c, Default_Shipment_Type__c, Name
				FROM Account
				WHERE Id = :accountId
		];

	}


	public static List<Order> getOrdersByAccountId(Id accountId) {
		return [
				SELECT Id, OrderNumber, Account.Name, Status, OrderedDate
				FROM Order
				WHERE AccountId = :accountId
		];
	}

	public static List<OrderSummary> getOrderSummaryById(Id orderId ) {
		return [
				SELECT AccountId, Account.Name, BillingAddress,BillingCity,BillingCountry,BillingEmailAddress,
				BillingPostalCode,BillingState,BillingStreet, Description,GrandTotalAmount,
				Id,OrderedDate,OrderNumber,OriginalOrderId,PoNumber,Status,TotalAmount,IsHold__c
				FROM OrderSummary
				where Id = :orderId				
				order by OrderedDate DESC
		];
	}

	public static List<Order> getExternalActivatedOrders(Set<Id> orderIds) {
		return [
			SELECT Id, External__c
			FROM Order
			where Id IN :orderIds
			AND External__c = true
			AND Status = 'Activated'
		];
	}

	public static List<OrderSummary> getOrderSummaryByOriginalOrderId(List<Id> originalOrderIds ) {
		return [
				SELECT AccountId, Account.Name, BillingAddress,BillingCity,BillingCountry,BillingEmailAddress,
				BillingPostalCode,BillingState,BillingStreet, Description,GrandTotalAmount,
				Id,OrderedDate,OrderNumber,OriginalOrderId,PoNumber,Status,TotalAmount,IsHold__c 
				FROM OrderSummary
				where OriginalOrderId IN :originalOrderIds				
				order by OrderedDate DESC
		];
	}

	public static List<OrderItemSummary> getOrderItemSummaryByOrderSummaryId(Id orderSummaryId ) {
		return [
			SELECT Id,Name,OrderDeliveryGroupSummaryId,OrderSummaryId,OriginalOrderItemId,Product2Id,Product2.Name,
			Product2.MaterialNumber__c,
			ProductCode,Quantity,Status,StockKeepingUnit,TotalLineAmount 
			FROM OrderItemSummary
			Where OrderSummaryId = :orderSummaryId
		];
	}

	public static List<OrderDeliveryGroupSummary> getOrderDeliveryGroupSummaryByOrderSummaryId(Id orderSummaryId ) {
		return [
			SELECT AccountExternalNumber__c,BOLNumber__c,DeliverToAddress,DeliverToCity,DeliverToCountry,DeliverToName,DeliverToPostalCode,AccessCode__c,
			DeliverToState,DeliverToStreet,DeliveryInstructions,Description,DesiredDeliveryDate,Id,MaterialNumber__c,OriginalMaterialNumber__c,
			OrderDeliveryGroupSummaryNumber,OrderDeliveryMethodId,OrderSummaryId,OriginalOrderDeliveryGroupId,PONumber__c,Quantity__c,
			QuoteNumber__c,ShipmentDateTime__c,ShipmentSizeType__c,Shipment_Size_Type_Label__c,ShipmentSize__c,ShipmentTonnage__c,ShipmentWeight__c,ShipmentStatus__c,
			Cancel_Requested_On__c, Cancel_Requested_By__r.FirstName, Canceled_On__c, Canceled_By__r.FirstName, IsHold__c, Released_On__c, Released_By__r.FirstName
			FROM OrderDeliveryGroupSummary
			Where OrderSummaryId = :orderSummaryId
			order by MaterialNumber__c, DesiredDeliveryDate 
		];
	}


	public static List<Order> getOrderById(Id orderId ) {
		return [
				SELECT AccountId, Account.Name, BillingAddress,BillingCity,BillingCountry,BillingEmailAddress,
				BillingPostalCode,BillingState,BillingStreet, Description,GrandTotalAmount,
				Id,OrderedDate,OrderNumber,PoNumber,Status,TotalAmount
				FROM Order
				where Id = :orderId				
				order by OrderedDate DESC
		];
	}

	public static List<OrderItem> getOrderItemByOrderId(Id orderId ) {
		return [
			SELECT Id,OrderDeliveryGroupId,OrderId,Product2Id,Product2.Name,
			Product2.MaterialNumber__c,
			Product2.ProductCode,Quantity,TotalLineAmount 
			FROM OrderItem
			Where OrderId = :orderId
		];
	}

	public static List<OrderDeliveryGroup> getOrderDeliveryGroupByOrderId(Id orderId ) {
		return [
			SELECT AccountExternalNumber__c,BOLNumber__c,DeliverToAddress,DeliverToCity,DeliverToCountry,DeliverToName,DeliverToPostalCode,AccessCode__c,
			DeliverToState,DeliverToStreet,DeliveryInstructions,Description,DesiredDeliveryDate,Id,MaterialNumber__c,OriginalMaterialNumber__c,
			OrderDeliveryGroupNumber,OrderDeliveryMethodId,OrderId,PONumber__c,Quantity__c,
			QuoteNumber__c,ShipmentDateTime__c,ShipmentSizeType__c,ShipmentSize__c,ShipmentTonnage__c,ShipmentWeight__c,ShipmentStatus__c,
			Cancel_Requested_On__c, Cancel_Requested_By__r.FirstName, Canceled_On__c, Canceled_By__r.FirstName, IsHold__c, Released_On__c, Released_By__r.FirstName
			FROM OrderDeliveryGroup
			Where OrderId = :orderId
			order by MaterialNumber__c, DesiredDeliveryDate 
		];
	}

	@AuraEnabled
	public static Integer shouldUserSeeSurveyPopup(String accountId) {
		Integer numOrders = 0;

		List<Account> effectiveAccount = [SELECT Id, Number_of_Orders__c
									FROM Account
									WHERE Id=:accountId LIMIT 1];

		if(effectiveAccount.size() > 0) {
			effectiveAccount[0].Number_of_Orders__c += 1;
			update effectiveAccount;
			numOrders = effectiveAccount[0].Number_of_Orders__c.intValue();
		}

		//system.debug('Remainder: ' + math.mod(numOrders, 3));

		Integer remainder = math.mod(numOrders, 10);

		return remainder;
	}

	@AuraEnabled(cacheable=true)
    public static List<Product2> getProductById(String productId) {
        return [SELECT Id, Shipping_Condition_Label__c, Shipment_Size_Type_Label__c, Ship__c
				FROM Product2
				WHERE Id=:productId LIMIT 1];
    }
}