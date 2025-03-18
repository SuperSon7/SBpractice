package com.mystyle.sbb;

import org.springframework.security.authentication.AuthenticationManager;

import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.header.writers.frameoptions.XFrameOptionsHeaderWriter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import com.mystyle.sbb.user.UserSecurityService;

import lombok.RequiredArgsConstructor;

import com.mystyle.sbb.user.CustomOAuth2UserService;

@RequiredArgsConstructor
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {
	
	private final CustomOAuth2UserService customOAuth2UserService;
	private final UserSecurityService userSecurityService;
	
	@Bean
	SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
		http
			.authorizeHttpRequests((authorizeHttpRequests) -> 
				authorizeHttpRequests
					.requestMatchers(new AntPathRequestMatcher("/**")).permitAll()
			)
			
			.csrf((csrf) -> 
				csrf
					.ignoringRequestMatchers(new AntPathRequestMatcher("/h2-console/**"))
			)
			
			.headers((headers) -> 
				headers
					.addHeaderWriter(new XFrameOptionsHeaderWriter(
							XFrameOptionsHeaderWriter.XFrameOptionsMode.SAMEORIGIN))
			)
			
			.formLogin((formLogin) -> 
				formLogin
					.loginPage("/user/login")
					.defaultSuccessUrl("/")
			)
			
            .logout((logout) -> 
            	logout
                    .logoutRequestMatcher(new AntPathRequestMatcher("/user/logout"))
                    .logoutSuccessUrl("/")
                    .invalidateHttpSession(true)
            )
            //OAuth2 로그인 설정 추가
            .oauth2Login(oauth2 -> 
            	oauth2
            		.loginPage("/user/login")
            		.defaultSuccessUrl("/")
            		.userInfoEndpoint(userInfo -> 
            			userInfo.userService(customOAuth2UserService)
					)
    		);
		
		return http.build();

	}

    @Bean
    AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }


}
