@IsTest
public class TestDataFactory {
    private static Map<String, Profile> profileMap = new Map<String, Profile>();
    private static Map<String, UserRole> userRoleMap = new Map<String, UserRole>();

    public static Account createAccount(String name, Boolean pCommit) {
        return createAccount(null, name, pCommit);
    }
    public static Account createAccount(Id parentId, String name, Boolean pCommit) {
        String randomStr = '1' + getRandomString(8);
        Account newRecord = new Account(Name = name,        
        ShippingStreet = 'Test Street', ShippingCity = 'Cleveland', ShippingPostalCode = '44114', ShippingCountry = 'United States', AccountExternalNumber__c = '123');
        if (pCommit == true) {
            insert newRecord;
        }
        return newRecord;
    }


    public static Contact createContact(String firstName, String lastName, String email, Boolean pCommit) {
        return createContact(null, firstName, lastName, email, pCommit);
    }
    public static Contact createContact(Id accountId, String firstName, String lastName, String email,
            Boolean pCommit) {
        Contact newRecord = new Contact(AccountId = accountId, FirstName = firstName, LastName = lastName, Email = email, Phone = '0123456789',
                MailingStreet = 'Test Street', MailingCity = 'New York', MailingState = 'New York', MailingPostalCode = '12345',
                MailingCountry = 'United States', MailingLatitude = 40.11, MailingLongitude = -73.00,
                Birthdate = Date.today().addYears(-30));

        if (pCommit == true) {
            insert newRecord;
        }
        return newRecord;
    }

    public static User createUser(String firstName, String lastName, String email, String userName, String profileName, String roleName, Boolean pCommit) {
        return createUser(null, firstName, lastName, email, userName, profileName, roleName, pCommit);
    }
    public static User createCommunityUser(Id contactId, String firstName, String lastName, String email, String userName, String profileName, Boolean pCommit) {
        return createUser(contactId, firstName, lastName, email, userName, profileName, null, pCommit);
    }
    public static User createUser(Id contactId, String firstName, String lastName, String email, String userName, String profileName, String roleName, Boolean pCommit) {
        List<Profile> profiles = (profileMap.containsKey(profileName)) ? new List<Profile> { profileMap.get(profileName) }
                                : [SELECT Id, Name FROM Profile WHERE Name = :profileName LIMIT 1];
       
                                List<UserRole> userRoles = (roleName != null) ? (userRoleMap.containsKey(roleName)) ? new List<UserRole> { userRoleMap.get(roleName) }
                                : [SELECT Id, Name FROM UserRole WHERE Name = :roleName LIMIT 1] : null;
        User newRecord = new User(FirstName = firstName, LastName = lastName, Email = email, Username = userName,
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles');
               
        newRecord.Alias = (userName.length() > 8) ? userName.substring(0, 8) : userName;
        newRecord.CommunityNickname = newRecord.Alias;
        
        if (contactId != null) { newRecord.ContactId = contactId; }
        if (!profiles.isEmpty()) {
            newRecord.ProfileId = profiles[0].Id;
            profileMap.put(profileName, profiles[0]);
        }
        
        if (userRoles != null && !userRoles.isEmpty()) {
            newRecord.UserRoleId = userRoles[0].Id;
            userRoleMap.put(roleName, userRoles[0]);
        } 
       
        if (pCommit) {
            insert newRecord;
        }
       
        return newRecord;
    }

    public static PriceBook2 createPriceBook(String name)
    {
        PriceBook2 customPB=new PriceBook2();
        customPB.name=name;
        customPB.isActive=true;
        insert customPB;
        return customPB;
    }
    public static Product2 createProduct(String name)
    {
        Product2 prod=new Product2();
        prod.name=name;
        prod.IsActive=true;
        prod.Description='Test Product Entry 1';
        prod.ProductCode ='testproduct1';        
        prod.Family = 'Lime';
        prod.MaterialNumber__c = '000000000000010325';
        prod.ProductCode = '10325';
        insert prod;
        return prod;
    }

    public static PricebookEntry createPriceBookEntry(String priceBookID,Product2 prodct)
    {
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = priceBookID, Product2Id = prodct.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        return standardPrice;
    }

    
    public static Product2 createProduct(){
        Product2 prod = new Product2(Name = 'HiCal QL Pulv W/Flo Aid Bulk',
                                     Family = 'Lime', MaterialNumber__c = '000000000000010325', ProductCode = '10325');
        insert prod;
       
        Id pricebookId = Test.getStandardPricebookId();
       
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        return prod;
    }

    public static OrderSummary createOrderSummary(Id orderId, Id accountId){
        OrderSummary os = new OrderSummary();        
        //os.AccountId = accountId; 
        //os.OriginalOrderId = orderId;       
        // os.Status = 'Created';
        // os.OrderNumber = '123';
        // os.OrderedDate = Date.today();        
        // os.PoNumber = '123';
        // os.Description = 'test';
        // os.BillingCity =  'New York';
        // os.BillingCountry = 'United States';
        // os.BillingState =  'New York';
        // os.BillingStreet = '2 Paget';
        // os.BillingPostalCode =  '12345';
        insert os;
        return os;
    } 

    public static OrderItemSummary createOrderItemSummary(OrderSummary os, Product2 p){
        OrderItemSummary ois = new OrderItemSummary();
        ois.OrderSummaryId = os.Id;
        ois.Product2Id = p.Id;
        ois.Quantity = 1;
        //ois.OrderDeliveryGroupSummaryId;   
        insert ois;    
        return ois;        
    } 

    public static OrderDeliveryGroupSummary createOrderDeliveryGroupSummary(OrderSummary os){
        OrderDeliveryGroupSummary odgs = new OrderDeliveryGroupSummary();        
        odgs.AccessCode__c = '123';
        odgs.BOLNumber__c = '';
        odgs.AccountExternalNumber__c = '123';
        odgs.MaterialNumber__c = '000000000000010325';
        odgs.DesiredDeliveryDate = Date.today();        
        odgs.OrderSummaryId = os.Id;
        odgs.Quantity__c = 1;
        odgs.PONumber__c = '123';
        odgs.Description = '';
        odgs.DeliveryInstructions = '';
        odgs.ShipmentTonnage__c = 900;        
        odgs.ShipmentStatus__c = '2021-04-06'; 
        odgs.ShipmentWeight__c = '100';
        odgs.ShipmentSize__c = 10;
        odgs.ShipmentSizeType__c = 'Truck';
        odgs.ShipmentDateTime__c = Date.today(); 
        odgs.DeliverToName = '';
        odgs.DeliverToCity =  'New York';
        odgs.DeliverToCountry = 'United States';
        odgs.DeliverToState =  'New York';
        odgs.DeliverToStreet = '2 Paget';
        odgs.DeliverToPostalCode =  '12345';
        insert odgs;
        return odgs;
    } 

    public static WebStore createWebStore(){
        WebStore ws =  new WebStore();       
        ws.Name = 'Test';
        insert ws;
        return ws;
    }

    public static WebCart createCart(Id accountId, Id StoreId){
        WebCart c =  new WebCart();
        c.AccountId = accountId;
        c.Name = 'Test';
        c.WebStoreId = StoreId;
        insert c;
        return c;
    }

    public static CartItem createCartItem(Id cartId){
        CartItem ci =  new CartItem();
        ci.CartId = cartId; 
        //ci.Name = 'HiCal QL Pulv W/Flo Aid Bulk';    
        //ci.MaterialNumber__c = '000000000000010325';      
        //ci.Quantity = 1;
        insert ci;
        return ci;
    }

    public static CartDeliveryGroup createCartDeliveryGroup(Id cartId){
        CartDeliveryGroup cdg =  new CartDeliveryGroup();
        cdg.AccountExternalNumber__c = '123'; 
        cdg.MaterialNumber__c = '000000000000010325';      
        cdg.Quantity__c = 1;
        insert cdg;
        return cdg;
    }
        
    

    public static String getRandomString(Integer pLength) {
        String oStr = EncodingUtil.convertToHex(Crypto.generateAesKey(192));
        return (pLength != null && oStr.length() > pLength) ? oStr.substring(0, pLength) : oStr;
    }

    public static String toLowerCase(String str) {
        return (str != null) ? str.toLowerCase() : str;
    }

    public static String getRandomUsername() {
        return getRandomString(8) + '@carmeuse.com.test';
    }
    
}