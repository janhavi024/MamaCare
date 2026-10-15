package com.mamacare.user;

/** PENDING/REJECTED accounts can sign in but only see their status; SUSPENDED accounts are blocked. */
public enum AccountStatus { ACTIVE, PENDING, REJECTED, SUSPENDED }
