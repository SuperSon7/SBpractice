package com.mystyle.sbb.user;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import com.mystyle.sbb.user.UserRole;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
@Service
public class CustomOAuth2UserService implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {
	//OAuth2 제공자로 부터 받은 사용자 정보를 처리하는 것이 핵심
	private final UserRepository userRepository;
	private final PasswordEncoder passwordEncoder;
	
	//OAuth2 사용자 정보를 가져오기
	@Override
	public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
		// 기본 OAuth2UserService 객체 생성
		OAuth2UserService<OAuth2UserRequest, OAuth2User> delegate = new DefaultOAuth2UserService();
		// OAuth2UserService를 통해 OAuth2User 정보를 가져옴
		OAuth2User oAuth2User = delegate.loadUser(userRequest);
		
		// 현재 로그인 진행중인 서비스 구분
		String registrationId = userRequest.getClientRegistration().getRegistrationId();
		
		// OAuth2 로그인 진행 시 키가 되는 필드값을 이야기함. Primary Key 와 같은 의미, 구글은 sub, 네이버는 response
		String userNameAttributeName = userRequest.getClientRegistration().getProviderDetails()
				.getUserInfoEndpoint().getUserNameAttributeName();
		
		// OAuth2UserService를 통해 가져온 OAuth2User의 attribute 를 담을 클래스
		OAuthAttributes attributes = OAuthAttributes.of(registrationId, userNameAttributeName, oAuth2User.getAttributes());
		
		//DB에 유저 저장 또는 업데이트
		SiteUser siteUser = saveOrUpdate(attributes);
		
		//권한 설정
		List<GrantedAuthority> authorities = new ArrayList<>();
		if ("admin".equals(siteUser.getUsername())) {
			authorities.add(new SimpleGrantedAuthority(UserRole.ADMIN.getValue()));
		} else {
			authorities.add(new SimpleGrantedAuthority(UserRole.USER.getValue()));
		}
		
		// DefaultOAuth2User 객체를 생성해서 반환
		return new DefaultOAuth2User(
				authorities,
				attributes.getAttributes(),
				attributes.getNameAttributeKey());
		
	}
	
	// 기존사용자인지 확인하고 새로 생성하거나 업데이트 하기
    private SiteUser saveOrUpdate(OAuthAttributes attributes) {
        Optional<SiteUser> userOptional = userRepository.findByEmail(attributes.getEmail());
        
        if (userOptional.isPresent()) {
            // 기존 사용자 - 필요한 경우 정보 업데이트
            return userOptional.get();
        } else {
            // 신규 사용자 생성
            SiteUser user = new SiteUser();
            user.setUsername(attributes.getUsername());
            user.setEmail(attributes.getEmail());
            
            // OAuth2 사용자는 실제 비밀번호가 없으므로 임의의 비밀번호 생성
            // 이 비밀번호는 사용되지 않지만, null이 되지 않도록 함
            String randomPassword = UUID.randomUUID().toString();
            user.setPassword(passwordEncoder.encode(randomPassword));
           
            return userRepository.save(user);
        }
	}
}
