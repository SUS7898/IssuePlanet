package com.care.boot.member;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;


@Controller
public class MemberController {
	@Autowired	private MemberService service ;
	@Autowired private HttpSession session;
	
	@RequestMapping("regist")
	public String regist() {
		return "member/regist";
	}
	
	@PostMapping("registProc")
	public String registProc(MemberDTO member, Model model, RedirectAttributes ra) {
		
//		if(member.getAddress() != null && member.getAddress().trim().isEmpty() == false)
//			member.setAddress( postcode + "," + member.getAddress() + "," + detailAddress);
//		
		String msg = service.registProc(member);
		
		if(msg.equals("회원 등록 완료")) {
			ra.addFlashAttribute("msg", msg);
			return "redirect:index";
//			return "index";
		}
		
		model.addAttribute("msg", msg);
		return "member/regist";
	}
	
	@RequestMapping("login")
	public String login() {
		return "member/login";
	}
	
	@PostMapping("loginProc")
	public String loginProc(String id, String pw, Model model, RedirectAttributes ra) {
		String msg = service.loginProc(id, pw);
		if(msg.equals("로그인 성공")) {
			ra.addFlashAttribute("msg", msg);
			return "redirect:index";
		}
		model.addAttribute("msg", msg);
		return "member/login";
	}
	
	
	@RequestMapping("logout")
	public String logout(RedirectAttributes ra) {
		session.invalidate();
		ra.addFlashAttribute("msg", "로그 아웃");
		
		kakaoService.unlink();
		return "redirect:index";
	}
	
	@RequestMapping("memberInfo")
	public String memberInfo(String select, String search,
			@RequestParam(value="currentPage", required = false) String cp, Model model) {
		service.memberInfo(select, search, cp, model);
		return "member/memberInfo";
	}
	
	@RequestMapping("userInfo")
	public String userInfo(String id, Model model,  RedirectAttributes ra) {
		String msg = service.userInfo(id, model);
		if(msg.equals("회원 검색 완료"))
			return "member/userInfo";
		
		ra.addFlashAttribute("msg", msg);
		return "redirect:memberInfo";
	}
	
	//http://localhost:8086/dbQuiz/update
	@RequestMapping("update")
	public String update() {
		String sessionId = (String)session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		
		return "member/update";
	}
	
	@PostMapping("updateProc")
	public String updateProc(MemberDTO member, Model model) {
		String sessionId = (String)session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		
		member.setId(sessionId);
		String msg = service.updateProc(member);
		if(msg.equals("회원 수정 완료")) {
			session.invalidate();
			return "redirect:index";
		}
		
		model.addAttribute("msg", msg);
		return "member/update";
	}
	
	//http://localhost:8086/dbQuiz/delete
	@RequestMapping("delete")
	public String delete() {
		String sessionId = (String)session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		
		return "member/delete";
	}
	
	@PostMapping("deleteProc")
	public String deleteProc(MemberDTO member, Model model) {
		String sessionId = (String)session.getAttribute("id");
		if(sessionId == null)
			return "redirect:login";
		
		member.setId(sessionId);
		String msg = service.deleteProc(member);
		if(msg.equals("회원 삭제 완료")) {
			session.invalidate();
			return "redirect:index";
		}
		
		model.addAttribute("msg", msg);
		return "member/delete";
	}
	
	/*
	 http://localhost:8086/dbQuiz/kakaoLogin?
	 code=G2QFgIqYioKud_fa02jp1mikcoWU6ccLmKC_-T0xgHFoZlqddz74QKyM9sowSyG0x1c
	 xjwo9c00AAAGLA55NoQ
	 */
	@RequestMapping("kakaoLogin")
	public String kakaoLogin(String code) {
		System.out.println("code : " + code);
		kakaoService.getAccessToken(code);
		kakaoService.getUserInfo();
		
		return "redirect:index";
	}
	@Autowired private KakaoService kakaoService;
	
	
}









