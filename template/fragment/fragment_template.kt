package ${PACKAGE_NAME}

import androidx.fragment.app.viewModels
import ${applicationId}.R
import ${applicationId}.BR
import ${applicationId}.databinding.Fragment${NAME}Binding
import com.studio.common.ui.base.BaseBindingFragment
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class ${NAME}Fragment : BaseBindingFragment<${NAME}ViewModel, Fragment${NAME}Binding>() {
    
    override val viewModel by viewModels<${NAME}ViewModel>()
    
    override fun getLayoutId(): Int = R.layout.fragment_${lower_name}
    
    override fun isEnableBackDevice(): Boolean = true

    override fun getViewModelBindingVariable(): Int = BR.viewModel

    override fun initView() {
        Unit
    }

    override fun initViewModel() {
        Unit
    }
}