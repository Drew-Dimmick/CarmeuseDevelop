@isTest
public with sharing class OrderDeliveryGroupExecutorTest {
    @IsTest(SeeAllData=true)
    static void testOrderDeliveryGroupInsert() {
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name='624 - STEEL DYNAMICS BUTLER - EAF'];

        Order testOrder = new Order(Name='Test Order', AccountId=testAccount.Id, EffectiveDate=Date.today(), Status='Draft');
        insert testOrder;

        Order insertedOrder = [SELECT Id, Name FROM Order WHERE Name='Test Order' LIMIT 1]; 

        OrderDeliveryGroup odg = new OrderDeliveryGroup(OrderId=insertedOrder.Id, BOLNumber__c='TestBOLNumber', DeliverToName='Test Address');
        insert odg;

        List<Bill_Of_Lading__c> testBOL = [SELECT Id, BOL_Number__c FROM Bill_Of_Lading__c WHERE BOL_Number__c='TestBOLNumber'];

        System.assertEquals(1, testBOL.size(), 'Should be of size 1');
    }

    @IsTest(SeeAllData=true)
    static void testOrderDeliveryGroupUpdate() {
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name='624 - STEEL DYNAMICS BUTLER - EAF'];

        Order testOrder = new Order(Name='Test Order', AccountId=testAccount.Id, EffectiveDate=Date.today(), Status='Draft');
        insert testOrder;

        Order insertedOrder = [SELECT Id, Name FROM Order WHERE Name='Test Order' LIMIT 1]; 

        OrderDeliveryGroup odg = new OrderDeliveryGroup(OrderId=insertedOrder.Id, BOLNumber__c='TestBOLNumber', DeliverToName='Test Address');
        insert odg;

        OrderDeliveryGroup insertedODG = [SELECT Id, BOLNumber__c FROM OrderDeliveryGroup WHERE BOLNumber__c='TestBOLNumber' LIMIT 1];
        insertedODG.BOLNumber__c = 'UpdatedBOLNumber';
        update insertedODG;

        List<Bill_Of_Lading__c> testBOL = [SELECT Id, BOL_Number__c FROM Bill_Of_Lading__c WHERE BOL_Number__c='UpdatedBOLNumber'];

        System.assertEquals(1, testBOL.size(), 'Should be of size 1');
    }
}
