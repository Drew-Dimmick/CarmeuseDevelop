@isTest
public with sharing class B2BSplitShipmentTest {
	public static testMethod void getSplitShipmentDefaults_getsDefaults() {

		// String result;

		// Test.startTest();

		// 	result = B2BSplitShipment.getSplitShipmentDefaults();

		// Test.stopTest();

		// System.assertNotEquals(null, result);
	}

    @IsTest(SeeAllData=true)
	public static void splitShipments_createsCartDeliveryGroups() {

		User communityUser = [SELECT Id FROM User WHERE Profile.Name = 'Base Customer Community Plus User' AND IsActive = TRUE LIMIT 1];

		final String TEST_PRODUCT_NAME = 'TestProduct';

        Product2 prod = new Product2(Name = 'HiCal QL Pulv W/Flo Aid Bulk',
                                     Family = 'Lime', MaterialNumber__c = '000000000000010325', ProductCode = '10325');
        insert prod;
       
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;

		//Pricebook2 stdPricebook = [SELECT Id, Name FROM Pricebook2 WHERE Name = :pricebookId LIMIT 1];
		// List<PriceBook2> stdPricebook = [SELECT Id, Name
        //                                 FROM PriceBook2
        //                                 WHERE Name='Standard Price Book' LIMIT 1];

        // Id priceBookId;
        // if(stdPricebook.size() > 0) {
        //     priceBookId = stdPricebook[0].Id;
        // }
		// System.debug('--- pricebook ---');
		// System.debug(stdPricebook);
       
        // PricebookEntry standardPrice = new PricebookEntry(
        //     Pricebook2Id = priceBookId, Product2Id = prod.Id,
        //     UnitPrice = 10000, IsActive = true, Quote_Number__c = '456');
        // insert standardPrice;

		Account testAccount = new Account(Name='Standard Price Book',BillingStreet='Test Street', BillingCountry='United States', BillingPostalCode='44444', AccountExternalNumber__c = '123');
		insert testAccount;

		// BuyerAccount buyerAccount = new BuyerAccount(name='test', BuyerId=testAccount.Id, IsActive=true);
		// insert buyerAccount;

		// BuyerGroup buyerGroup = new BuyerGroup(Name='buyerGroupTest');
		// insert buyerGroup;

		// BuyerGroupMember buyerGroupMember = new BuyerGroupMember(BuyerId=buyerAccount.BuyerId,BuyerGroupId=buyerGroup.Id);
		// insert buyerGroupMember;

		List<WebStore> testWebStore = [SELECT Id FROM WebStore WHERE Name='Carmeuse Customer Portal'];

		// WebStoreBuyerGroup webStoreBuyerGroup = new WebStoreBuyerGroup(BuyerGroupId=buyerGroup.Id, WebStoreId= testWebStore[0].Id);
		// insert webStoreBuyerGroup;

		List<WebStoreNetwork> community = [SELECT NetworkId FROM WebStoreNetwork WHERE WebStoreId = :testWebStore[0].Id];

		WebCart cart = new WebCart(Name='Cart', WebStoreId=testWebStore[0].Id, AccountId=testAccount.Id);
		insert cart;

		CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
		insert cartDeliveryGroup;

		CartItem cartItem = new CartItem(CartId=cart.Id, Sku='SKU_Test1',TotalPrice=10.00, SalesPrice=10.00, Quantity=1.0, Type='Product', Name=TEST_PRODUCT_NAME, CartDeliveryGroupId=cartDeliveryGroup.Id, Product2Id=prod.Id);
		insert cartItem;

		CartCheckoutSession  ccs = new CartCheckoutSession(WebCartId = cart.Id, IsArchived = false, Name = cart.Name, State = 'Order Confirmation' );
		insert ccs;

		String testPayload = 
			// '"{"0a93O0000004IITQA2":' +
			'"' +
					'{"ProductDetail":' +
						'{"Product":"' + cartItem.Id + '","startDate":"2021-05-03","endDate":"2021-05-04","loadVolume":"5","shippingMode":"25","quantity":"1","poNumber":"1","deliveryText":"1"},' +
						'"listOfLineItem":[' + 
							'{"Product":"' + cartItem.Id + '","deliveryDate":"2021-05-03","Quantity":"1","Tonnage":"5","DeliveryText":"1","PoNumber":"1","index":0},' + 
							'{"Product":"' + cartItem.Id + '","deliveryDate":"2021-05-04","Quantity":"1","Tonnage":"5","DeliveryText":"1","PoNumber":"1","index":1}' + 
						']' + 
					'}"';

		Contact testContact = new Contact(FirstName='Test', LastName='Contact', AccountId=testAccount.Id);
		insert testContact;

		// UserRole testUserRole = [SELECT Id FROM UserRole LIMIT 1];

		User sysadminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		List<CartItem> testCartItems = [SELECT Id FROM CartItem WHERE CartId = :cart.Id];
		System.debug(testCartItems);

		Test.startTest();
			// System.runAs(communityUser) {
				testCartItems = [SELECT Id FROM CartItem WHERE CartId = :cart.Id];
				System.debug(testCartItems);

				B2BSplitShipment.splitShipments(cart.Id, testPayload);
				
			// }
		Test.stopTest();
	}
}