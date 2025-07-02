package com.mystyle.sbb.user;

import lombok.Getter;
import lombok.Builder;

import java.util.Map;

@Getter
public class OAuthAttributes {
    private Map<String, Object> attributes;
    private String nameAttributeKey;
    private String name;
    private String email;
    private String username;
    
    @Builder
    public OAuthAttributes(Map<String, Object> attributes, String nameAttributeKey, String name, String email, String username) {
		this.attributes = attributes;
		this.nameAttributeKey = nameAttributeKey;
		this.name = name;
		this.email = email;
		this.username = username;
	}
    
    //OAuth2User에서 반환하는 사용자 정보는 Map 이기 때문에 값 하나하나를 변환해야만 함
    public static OAuthAttributes of(String registrationId, String userNameAttributeName, Map<String, Object> attributes) {
		if("naver".equals(registrationId)) {
			return ofNaver("id", attributes);
		}
		return ofGoogle(userNameAttributeName, attributes);
	}
    
    //구글로그인
    public static OAuthAttributes ofGoogle(String userNameAttributeName, Map<String, Object> attributes) {
    	String email = (String) attributes.get("email");
    	
    	return OAuthAttributes.builder()
				.name((String) attributes.get("name"))
				.email(email) // 이메일을 기본 사용자명으로 사용
				.username(email)
				.attributes(attributes)
				.nameAttributeKey(userNameAttributeName)
				.build();
    }
    
    //네이버로그인
    public static OAuthAttributes ofNaver(String userNameAttributeName, Map<String, Object> attributes) {
		Map<String, Object> response = (Map<String, Object>) attributes.get("response");
		
		return OAuthAttributes.builder()
				.name((String) response.get("name"))
				.email((String) response.get("email"))
				.username((String) response.get("id"))
				.attributes(response)
				.nameAttributeKey(userNameAttributeName)
				.build();
    }
    
    //SiteUser 엔티티를 생성
    public SiteUser toEntity() {
    	SiteUser siteUser = new SiteUser();
    	siteUser.setUsername(username);
    	siteUser.setEmail(email);
    	//OAuth2 로그인 사용자의 경우 비밀번호가 없으므로 임의의 값 또는 null 처리
    	return siteUser;
    }

}
