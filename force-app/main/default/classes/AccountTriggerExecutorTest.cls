@isTest(SeeAllData=true)
public with sharing class AccountTriggerExecutorTest {
    @IsTest
    static void testAccountCreation() { // rename
        Account testAccount = new Account(Name='TestAccount',BillingStreet='Test Street', BillingCountry='United States', BillingPostalCode='44444', AccountExternalNumber__c = '123');
		Test.startTest();
        insert testAccount; // throw into start test stop test block
        update testAccount;
        Test.stopTest();

        String accountName = testAccount.Name;

        String bgName = 'BG-' + accountName;
        List<BuyerGroup> testAccountBuyerGroup = [SELECT Id, Name FROM BuyerGroup WHERE Name=:bgName];

        String epName = 'EP-' + accountName;
        List<CommerceEntitlementPolicy> testAccountEP = [SELECT Id, Name FROM CommerceEntitlementPolicy WHERE Name=:epName];

        System.assertEquals(1, testAccountBuyerGroup.size(), 'Did not find Buyer Group'); // rephrase messages
        System.assertEquals(1, testAccountEP.size(), 'Did not find Entitlement Policy');

        //System.assertEquals(1, 1, 'Test');
    }
}
