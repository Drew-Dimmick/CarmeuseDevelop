trigger ProductTrigger on Product2 (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerExecutionHandler.execute(new ProductTriggerExecutor());
}