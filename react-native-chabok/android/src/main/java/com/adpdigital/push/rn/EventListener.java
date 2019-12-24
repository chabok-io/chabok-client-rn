package com.adpdigital.push.rn;

import com.adpdigital.push.PushMessage;

public interface EventListener {
    void onEvent(PushMessage push);
}