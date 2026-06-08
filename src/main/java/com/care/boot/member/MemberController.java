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
@RequestMapping("/member")
public class MemberController {
    
    @Autowired private MemberService service;
    @Autowired private HttpSession session;
    
    // 회원가입 페이지 이동
    @RequestMapping("/regist")
    public String regist() {
        return "member/regist";
    }
    
    // [수정] 회원가입 처리 로직
    @PostMapping("/registProc")
    public String registProc(MemberDTO member, Model model, RedirectAttributes ra) {
        String msg = service.registProc(member);
        
        if(msg.equals("회원 등록 완료")) {
            ra.addFlashAttribute("msg", msg);
            // "redirect:index" 대신 "redirect:/"를 사용하여 최상위 메인 루트 페이지로 이동시킵니다.
            return "redirect:/"; 
        }
        
        model.addAttribute("msg", msg);
        return "member/regist";
    }
    
    // 로그인 페이지 이동
    @RequestMapping("/login")
    public String login() {
        return "member/login";
    }
    
    // [수정] 로그인 처리 로직
    @PostMapping("/loginProc")
    public String loginProc(String id, String pw, Model model, RedirectAttributes ra) {
        String msg = service.loginProc(id, pw);
        if(msg.equals("로그인 성공")) {
            ra.addFlashAttribute("msg", msg);
            // 로그인 성공 시에도 똑같이 메인 루트 페이지로 안전하게 이동시킵니다.
            return "redirect:/";
        }
        model.addAttribute("msg", msg);
        return "member/login";
    }
    
    // 로그아웃 처리 로직
    @RequestMapping("/logout")
    public String logout(RedirectAttributes ra) {
        session.invalidate();
        ra.addFlashAttribute("msg", "로그 아웃 완료");
        return "redirect:/";
    }
    
    // ... 기존의 나머지 메서드들 (userInfo, update, delete 등)은 그대로 유지하시면 됩니다.
}