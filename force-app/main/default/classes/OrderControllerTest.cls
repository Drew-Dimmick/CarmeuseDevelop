/*----------------------------------------------------------------------
Name:       OrderControllerTest.cls
Purpose:    Test Class for OrderController class
------------------------------History----------------------------------
Version     Author          Date                    Detail Description 
-------     -------         --------------          ------------------
1.0         Devang          06-April-2021           Initial Development 
----------------------------------------------------------------------*/

@isTest
public with sharing class OrderControllerTest {
 
    @IsTest(SeeAllData=true)
	static void testGetOrderDetail() {
		final String TEST_PRODUCT_NAME = 'TestProduct';

        SalesChannel sc = new SalesChannel(SalesChannelName = 'SAP', Description = 'SAP');
        insert sc; 

		Product2 prod = new Product2(Name = 'HiCal QL Pulv W/Flo Aid Bulk',
		Family = 'Lime', MaterialNumber__c = '000000000000010325', ProductCode = '10325');
		insert prod;

        Id pricebookId = Test.getStandardPricebookId();
       
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        Pricebook2 pb = new Pricebook2 (Name = 'PB-TestAccount',  IsActive = true);
        insert pb;

        PricebookEntry custPrice = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert custPrice;

        ProductCatalog pc = new ProductCatalog(Name='My Catalog');
        insert pc;
        ProductCategory pcat = new ProductCategory(Name='Lime Products', CatalogId = pc.Id);
        insert pcat;
        ProductCategoryProduct pcp = new ProductCategoryProduct(ProductCategoryId = pcat.Id, ProductId = prod.Id );
        insert pcp;

		Account testAccount = new Account(Name='TestAccount',BillingStreet='Test Street', BillingCountry='United States', BillingPostalCode='44444', AccountExternalNumber__c = '123');
		insert testAccount;

		BuyerAccount buyerAccount = new BuyerAccount(name='test', BuyerId=testAccount.Id, IsActive=true);
		insert buyerAccount;

		BuyerGroup buyerGroup = new BuyerGroup(Name='buyerGroupTest');
		insert buyerGroup;

		BuyerGroupMember buyerGroupMember = new BuyerGroupMember(BuyerId=buyerAccount.BuyerId,BuyerGroupId=buyerGroup.Id);
		insert buyerGroupMember;

        //WebStore ws = new WebStore(Name='Carmeuse Customer Portal'); // Commented out by Drew Dimmick - Webstore Already exists & see all data is true
        //insert ws;

		List<WebStore> testWebStore = [SELECT Id FROM WebStore WHERE Name='Carmeuse Customer Portal' LIMIT 1];

        WebStorePricebook wspb = new WebStorePricebook ( IsActive = true, Pricebook2Id = pb.Id, WebStoreId = testWebStore[0].Id );
        insert wspb;

        CommerceEntitlementPolicy cep = new CommerceEntitlementPolicy(Name = 'Test Policy', IsActive = true, CanViewProduct = true);
        insert cep;

        CommerceEntitlementProduct ceprd = new CommerceEntitlementProduct(PolicyId = cep.Id, ProductId = prod.Id);
        insert ceprd;

        CommerceEntitlementBuyerGroup cebg = new CommerceEntitlementBuyerGroup(PolicyId = cep.Id, BuyerGroupId = buyerGroup.Id);
        insert cebg;

		WebStoreBuyerGroup webStoreBuyerGroup = new WebStoreBuyerGroup(BuyerGroupId=buyerGroup.Id, WebStoreId= testWebStore[0].Id);
		insert webStoreBuyerGroup;

		List<WebStoreNetwork> community = [SELECT NetworkId FROM WebStoreNetwork WHERE WebStoreId = :testWebStore[0].Id LIMIT 1];

		WebCart cart = new WebCart(Name='Cart', WebStoreId=testWebStore[0].Id, AccountId=testAccount.Id);
		insert cart;

		CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
		insert cartDeliveryGroup;

		CartItem cartItem = new CartItem(CartId=cart.Id, Sku='SKU_Test1',TotalPrice=10.00, SalesPrice=10.00, Quantity=1.0, Type='Product', Name=TEST_PRODUCT_NAME, CartDeliveryGroupId=cartDeliveryGroup.Id);
		insert cartItem;

		Test.startTest();
        ConnectApi.CartItemCollection cartItemCollection = B2BCartController.getCartItems(community[0].NetworkId, buyerAccount.BuyerId, cart.id,null,null );
        
		Order o = new Order();
        o.AccountId= testAccount.Id;  // Id from step 3
        o.SalesStoreId= testWebStore[0].Id; // Id from step 2
        o.Status='Draft';
        o.EffectiveDate=date.today();
        //o.OwnerId = buyerId;   // Id from step 5
        o.External__c = true; // very important
        insert o;

        OrderDeliveryMethod odm = [SELECT Id FROM OrderDeliveryMethod where Name = 'Default Delivery Method'];

        OrderDeliveryGroup odg = new OrderDeliveryGroup();
        odg.OrderId=o.id;
        odg.OrderDeliveryMethodId=odm.Id; // Id from step 1
        odg.DeliverToName='The Shipping Address';
        odg.AccessCode__c = '123';
        odg.BOLNumber__c = '';
        odg.AccountExternalNumber__c = '123';
        odg.MaterialNumber__c = '000000000000010325';
        odg.DesiredDeliveryDate = Date.today(); 
        odg.Quantity__c = 1;
        odg.PONumber__c = '123';
        odg.Description = '';
        odg.DeliveryInstructions = '';
        odg.ShipmentTonnage__c = 900;        
        odg.ShipmentStatus__c = '2021-04-06'; 
        odg.ShipmentWeight__c = '100';
        odg.ShipmentSize__c = 10;
        odg.ShipmentSizeType__c = '25';
        odg.ShipmentDateTime__c = Date.today(); 
        odg.DeliverToName = 'TestAccount';
        odg.DeliverToCity =  'New York';
        odg.DeliverToCountry = 'United States';
        odg.DeliverToState =  'New York';
        odg.DeliverToStreet = '2 Paget';
        odg.DeliverToPostalCode =  '12345';
        insert odg;

        OrderItem oi = new OrderItem();
        oi.OrderId=o.Id;
        oi.OrderDeliveryGroupId = odg.Id; //Id received from step 7
        oi.Product2Id=prod.Id; // Retrieve based on Material Number
        oi.Quantity=1;
        oi.ListPrice=999;
        oi.UnitPrice=999;
        oi.TotalLineAmount=999;
        oi.Type='Order Product';
        insert oi;

        Order o1 = new Order();
        o1.Id = o.Id ;
        o1.Status = 'Activated';
        update o1;

        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = o1.Id;
        osir.orderLifeCycleType = 'UNMANAGED';
        ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
        
        Order o2 = new Order();
        o2.Id = o.Id ;
        o2.Description = 'Test';
        update o2;
        List<Id> originalOrderIds = new List<Id>();		
		
		List<OrderSummary> osl = [SELECT Id FROM OrderSummary Limit 1];
        OrderController.OrderDetailWrapper od = OrderController.getOrderDetail(osl[0].Id);
		Id orderDeliveryGroupId = od.orderItemSummaryWrapperList[0].orderDeliveryGroupSummaryWrapperHeaderList[0].orderDeliveryGroupSummaryWrapperList[0].originalOrderDeliveryGroupId;
		Boolean isQuoteNumberUpdated =  OrderController.updateQuoteNumber(orderDeliveryGroupId, '12345');
		isQuoteNumberUpdated =  OrderController.updateOrderDeliveryGroupByCSR(orderDeliveryGroupId, '12345', '000000000018', '000000000018');
		Boolean isCancel =  OrderController.cancelOrderDeliveryGroupByCSR(orderDeliveryGroupId);
		String cancelMessage = OrderController.getCancelMessageOrderDeliveryGroupByCSR(orderDeliveryGroupId);
		Id accountId = OrderController.getAccountId();
        List<Order> accountOrders = OrderController.getUserOrders(accountId, null, 'EffectiveDate', 'desc', null, null);
        List<OrderSummary> orderSummary = OrderController.getOrderSummaryByOriginalOrderId(o1.Id);
        Order receivedOrder = OrderController.getOrderByOrderId(o1.Id);
        List<OrderDeliveryGroup> orderDGs = OrderController.getOrderDeliveryGroupByOrderId(o1.Id);
		odg =  OrderController.getOrderDeliveryGroupData(orderDeliveryGroupId);
		List<String> eel = OrderController.getExtendedEntitlement(testAccount.Id);
		Boolean isRelease = OrderController.releaseOrderDeliveryGroupByCSR(orderDeliveryGroupId);
		String message = OrderController.getReleaseMessageOrderDeliveryGroupByCSR(orderDeliveryGroupId);
        Boolean foundODGs = false;
        Boolean foundOrders = true;
        if(orderDGs.size() > 0) {
            foundODGs = true;
        }
        if(accountOrders.size() > 0) {
            foundOrders = true;
        }

		Test.stopTest();
        System.assertEquals(true, foundODGs, 'Value should be true');
        System.assertEquals(true, foundOrders, 'Value should be true');
        System.assertEquals('Activated', receivedOrder.Status, 'Status should be Activated');
        System.assertEquals(1, orderSummary.size(), 'Size Should be 1');
		System.assertEquals(TEST_PRODUCT_NAME, cartItemCollection.cartItems[0].cartItem.name, 'Name should be TestProduct');
		System.assertNotEquals(osl, null);
        System.assertNotEquals(odg, null);
	}
}