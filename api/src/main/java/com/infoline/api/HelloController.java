// api/src/main/java/com/infoline/api/HelloController.java

package com.infoline.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello from InfoLine API";
    }
}