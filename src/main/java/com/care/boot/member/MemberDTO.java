package com.care.boot.member;
/*
CREATE TABLE member(
id VARCHAR(20),
pw VARCHAR(60),
username VARCHAR(21),
postcode VARCHAR(10),
address VARCHAR(300),
detailaddress VARCHAR(300),
mobile VARCHAR(20),
PRIMARY KEY(id)
)DEFAULT CHARSET=UTF8;
*/
public class MemberDTO {
	private String id;
	private String pw;
	private String confirm;
	private String userName;
	private String postcode;
	private String address;
	private String detailAddress;
	private String mobile;
	
	public String getPostcode() {
		return postcode;
	}
	public void setPostcode(String postcode) {
		this.postcode = postcode;
	}
	public String getDetailAddress() {
		return detailAddress;
	}
	public void setDetailAddress(String detailAddress) {
		this.detailAddress = detailAddress;
	}
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getPw() {
		return pw;
	}
	public void setPw(String pw) {
		this.pw = pw;
	}
	public String getConfirm() {
		return confirm;
	}
	public void setConfirm(String confirm) {
		this.confirm = confirm;
	}
	public String getUserName() {
		return userName;
	}
	public void setUserName(String userName) {
		this.userName = userName;
	}
	public String getAddress() {
		return address;
	}
	public void setAddress(String address) {
		this.address = address;
	}
	public String getMobile() {
		return mobile;
	}
	public void setMobile(String mobile) {
		this.mobile = mobile;
	}
	
	
}

/*

INSERT INTO db_quiz VALUES('user1', '1111', '원유저', '서울시 유일구', '010-1111-1111');
INSERT INTO db_quiz VALUES('user2', '2222', '이유저', '서울시 유이구', '010-2222-1111');
INSERT INTO db_quiz VALUES('user3', '3333', '삼유저', '서울시 유삼구', '010-3333-1111');
INSERT INTO db_quiz VALUES('user4', '4444', '사유저', '서울시 유사구', '010-4444-1111');
INSERT INTO db_quiz VALUES('user5', '5555', '오유저', '서울시 유오구', '010-5555-1111');

INSERT INTO db_quiz VALUES('test1', '1111', '테스트1', '서울시 테일구', '010-1111-1111');
INSERT INTO db_quiz VALUES('test2', '2222', '테스트2', '서울시 테이구', '010-1111-2222');
INSERT INTO db_quiz VALUES('test3', '3333', '테스트3', '서울시 테삼구', '010-1111-3333');
INSERT INTO db_quiz VALUES('test4', '4444', '테스트4', '서울시 테사구', '010-1111-4444');
COMMIT;
*/





